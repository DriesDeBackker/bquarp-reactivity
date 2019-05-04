defmodule Reactivity.DSL.Signal do
	@moduledoc """
	The DSL for distributed reactive programming.
	"""
	alias Reactivity.Processing.CombineWithGuarantees
	alias Reactivity.Processing.CombineVarWithGuarantees
	alias Reactivity.Quality.Context
	alias Reactivity.Quality.Guarantee
	alias Reactivity.DSL.SignalObs, as: Sobs
	alias Reactivity.Registry

	alias Observables.Obs
  alias Observables.GenObservable

  require Logger

	@doc """
	Creates a signal from a plain observable.

	Attaches the given consistency guarantee to it if provided.
	Otherwise attaches the globally defined consistency guarantee,
	which is fifo with update semantics (`{:fu, 0}`) by default.
	"""
	def from_plain_obs(obs) do
		cg = Registry.get_guarantee
		from_plain_obs(obs, cg)
	end
	def from_plain_obs(obs, cg) do
		sig_obs = obs
		|> Sobs.from_plain_obs
		{:signal, sig_obs, []}
		|> add_guarantee(cg)
	end

	@doc """
	Creates a signal from a signal observable, tags it with the given guarantees.

	The assumption here is that the contexts of the observable have already been attached.
	The primitive can be used for guarantees with non-obvious contexts (other than e.g. counters)
	the developer might come up with.

	Attaches the given consistency guarantee to it if provided without changing the context.
	Otherwise attaches the globally defined consistency guarantee,
	which is fifo with update semantics (`{:fu, 0}`) by default.
	"""
	def from_signal_obs(sobs) do
		cg = Registry.get_guarantee
		from_signal_obs(sobs, [cg])
	end
	def from_signal_obs(sobs, cgs) do
		{:signal, sobs, cgs}
	end

	@doc """
	Transforms a signal into a plain observable.
	"""
	def to_plain_obs({:signal, sobs, _cgs}) do
		sobs
		|> Sobs.to_plain_obs
	end

	@doc """
	Transforms a signal into a signal observable,
	meaning that both the value and context {v, c} of each observable message are preserved.
	"""
	def to_signal_obs({:signal, sobs, _cgs}) do
		sobs
	end

	@doc """
	Attaches a new consistency guarantee to the signal.

	The signal may already possess one or more consistency guarantees.
	"""
	def add_guarantee({:signal, sobs, cgs}, cg) do
		new_sobs = sobs
		|> Sobs.add_context(cg)
		{:signal, new_sobs, cgs ++ [cg]}
	end

	@doc """
	Sets the given consistency guarantee as the only guarantee for the given signal.

	This can be considered the creation of a new source signal
	from another signal in a stratified dependency graph.
	"""
	def set_guarantee({:signal, sobs, _cgs}, cg) do
		new_sobs = sobs
		|> Sobs.set_context(cg)
		{:signal, new_sobs, [cg]}
	end

	@doc """
	Returns the guarantees of the given signal.
	"""
	def guarantees({:signal, _, cgs}), do: cgs

	@doc """
	Checks if the given signal carries the given guarantee.
	"""
	def carries_guarantee?({:signal, _sobs, cgs}, cg) do
		cgs
		|> Enum.any?(fn x -> x == cg end)
	end

	@doc """
	Removes the given guarantee from the given signal.
	Leaves the signal alone if the guarantee is not present.
	"""
	def remove_guarantee({:signal, sobs, cgs}, {cgt, _cgm}) do
		remove_guarantee({:signal, sobs, cgs}, cgt)
	end
	def remove_guarantee({:signal, sobs, cgs}, cgt) do
		i = cgs
		|> Enum.find_index(fn {xt, _xm} -> cgt == xt end)
		new_cgs = cgs
		|> List.delete_at(i)
		new_sobs = sobs
		|> Sobs.remove_context(i)
		{:signal, new_sobs, new_cgs}
	end

	@doc """
	Keeps the given guarantee as the only guarantee of the given signal.
	Removes all other guarantees.
	"""
	def keep_guarantee({:signal, sobs, cgs}, {cgt, _cgm}) do
		keep_guarantee({:signal, sobs, cgs}, cgt)
	end
	def keep_guarantee({:signal, sobs, cgs}, cgt) do
		i = cgs
		|> Enum.find_index(fn {xt, _xm} -> cgt == xt end)
		cg = cgs
		|> Enum.at(i)
		new_cgs = [cg]
		new_sobs = sobs
		|> Sobs.keep_context(i)
		{:signal, new_sobs, new_cgs}
	end

	@doc """
  Filters out the signal values that do not satisfy the given predicate.

  The expected function should take one argument, the value of an observable and return a boolean:
  true if the value should be produced, false if the value should be discarded.

  If no consistency guarantee is provided, it leaves the filtered signal 'as is'.
  The consequences of using this operator in this way are left to the developer.

  In the other case, a new consistency guarantee is attached to this signal,
  discarding the previous ones. Thus, filtering in this way can be considered as
  the creation of a new source signal for this guarantee in a stratified dependency graph
  """
	def filter({:signal, sobs, _cg}, pred, new_cg) do
		fobs = sobs
		|> Sobs.to_plain_obs
		|> Obs.filter(pred)
		|> Sobs.from_plain_obs
		|> Sobs.add_context(new_cg)
		{:signal, fobs, [new_cg]}
	end
	def filter({:signal, sobs, cgs}, pred) do
		fobs = sobs
		|> Obs.filter(fn {v, _cs} -> pred.(v) end)
		{:signal, fobs, cgs}
	end

	@doc """
	Merges multiple signals together such that the resulting signal carries the updates of all composed signals in a fifo fashion.

	If no consistency guarantee is provided, the merge leaves the updates 'as is'.
	A necessary condition for this operation to be valid then is that the givven signals all carry the same guarantee.
	The consequences of using this operator in this way are left to the developer.

	If however a consistency guarantee is provided, this new guarantee is attached to the resulting signal,
	discarding the previous ones. Thus, merging in this way can be considered to be
	the creation of a new source signal for this guarantee in a stratified dependency graph
	"""
	def merge(signals, new_cg) do
		sobss = signals
		|> Enum.map(fn {:signal, sobs, _cgs} -> sobs end)
		mobs = Obs.merge(sobss)
		|> Sobs.set_context(new_cg)
		{:signal, mobs, [new_cg]}
	end
	def merge([{:signal, _obs, cgs} | _st] = signals) do
		sobss = signals
		|> Enum.map(fn {:signal, sobs, _cgs} -> sobs end)
		mobs = Obs.merge(sobss)
		{:signal, mobs, cgs}
	end

	@doc """
	Merges multiple signals together such that the resulting signal carries the updates of all composed signals in a round-robin fashion.

	If no consistency guarantee is provided, rotate leaves the updates 'as is'.
	A necessary condition for this operation to be valid then is that the givven signals all carry the same guarantee.
	The consequences of using this operator in this way are left to the developer.

	If however a consistency guarantee is provided, this new guarantee is attached to the resulting signal,
	discarding the previous ones. Thus, using rotate in this way can be considered to be
	the creation of a new source signal for this guarantee in a stratified dependency graph.
	"""
	def rotate(signals, new_cg) do
		sobss = signals
		|> Enum.map(fn {:signal, sobs, _cgs} -> sobs end)
		robs = Obs.rotate(sobss)
		|> Sobs.set_context(new_cg)
		{:signal, robs, [new_cg]}
	end
	def rotate([{:signal, _obs, cgs} | _st] = signals) do
		sobss = signals
		|> Enum.map(fn {:signal, sobs, _cgs} -> sobs end)
		robs = Obs.rotate(sobss)
		{:signal, robs, cgs}
	end

	@doc """
  Applies a given procedure to a signal's value and its previous result. 
  Works in the same way as the Enum.scan function:
	
  Enum.scan(1..10, fn(x,y) -> x + y end)
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
  """
	def scan({:signal, sobs, cgs}, func, default \\ nil) do
		svobs = sobs
		|> Sobs.to_plain_obs
		|> Obs.scan(func, default)
		cobs = sobs
		|> Sobs.to_context_obs
		nobs = svobs
		|> Obs.zip(cobs)
		{:signal, nobs, cgs}
	end

	@doc """
	Applies a procedure to the values of a signal without changing them.
	Generally used for side effects.
	"""
	def each({:signal, sobs, cgs}, proc) do
		sobs
		|> Sobs.to_plain_obs
		|> Obs.each(proc)
		{:signal, sobs, cgs}
	end

	@doc """
	Lifts and applies an ordinary function to one or more signals

	Takes:
	* A list of signals carrying any consistency guarantees
	* A function taking the number of arguments that is equal to number of signals.

	Returns:
	* A signal for which the given function is applied to the input.

	Output for the resulting signal is only created if a newly received message from an input signal can be combined with the rest of the buffer
	under the consistency guarantees of the different signals.

	The resulting consistency guarantee of the output signal is a combination of the guarantees of the input signals.

	When combining signals:

	* With update semantics:
		- They have their last values kept as state until a more recent one is used.
		- Each value is regarded as an update that may trigger a new output.
		- This is similar to 'combine latest' in Reactive Extensions.
	* With propagate semantics:
	  - They have their used values kept only ntil they can be combined, at which point they are removed so they can't be used more than once.
	  - Each value is regarded as a value in a (time-series) data stream to be combined and propagated.
		- This is similar to 'zip' in Reactive Extensions.
	* With both update as well as propagate semantics:
		- New output is triggered by propagate-signals in steady state.
		- New input for update signals is kept as state to be combined with.
		- The first value of an update signal can trigger a series of outputs if there is a propagate history that has been waiting for this value to combine.
		- This is similar to 'combine latest silent' (with buffered propagation) in Reactive Extensions (specifically in the Observables Extended library)

	E.g.: `c = a + b` (with a, b and the resulting c all having `{:fu, _}` = update-fifo for guarantee)
	```
	a: 5 --------------------------------- 1 -->

	b: ------------- 3 --------- 5 ------------>

	c: -------------- 8 --------- 10 ------ 6 ->
	```

	E.g.: `c = a + b` (with a having `{:fu, _}`, b having `{:fp, _}` 
	and the resulting c having `[{:fu, _}, {:fp, _}]` for guarantee)
	```	
	a:  5 ------------------------------------ 1

	b:  ------------- 3 ------ 5 -------------->

	c:	-------------- 8 ------ 10 ------------>
	```

	E.g.: `c = a + b` (with a, b and the resulting c all having `{:fp, _}` = propagate-fifo for guarantee)
	```
	a: 5 --------------------------------- 1 -->

	b: ------------- 3 ---- 5 ----------------->

	c: -------------- 8 ------------------- 6 ->
	```

	E.g.: `c = a + b` (with a, b and the resulting c all having `{:t, 0}` = strict time-synchronization for guarantee)
	```
	a: 5(2) ----------- 3(3} -------------- 1(4) -------------->

	b: ---------- 4(1) ------------ 5(2) -------------- 3(3) -->

	c: ----------------------------- 10(2) --------------6(3) ->
	```

	E.g.: `c = a + b` (with a, b and the resulting c all having `{:t, 1}` = relaxed time-synchronization for guarantee)
	```
	a: 5(2) -------------- 3(3} ------------- 1(4) ------------>

	b: ---------- 4(1) -------------- 5(2) ------------- 3(3) ->

	c: ----------- 9(1,2) ------------- 8(2,3) ---------- 4(3,4)
	```

	E.g.: `c = a + b` (with a, b and the resulting c all having `{:c, 0}` = strict causality for guarantee)
	```
	a: 5(x2,y2) --------------------------------------- 2(x3,y3)

	b: -------- 3(x1) ---- 3(x2) --- 8(x3) --- 7(x4) ---------->

	c: -------------------- 8(..) --- 13(..) --- 12(..) -- 9(..)
	```
	(For more information: consult the DREAM academic paper by Salvaneschi et al.)


	E.g.: `d = a + b + c` (with a, b, c and the resulting d all having `{:g, 0}` = strict glitch freedom for guarantee)
	```
	a: 5(x2) ---------------------------------------- 2(x3) --->

	b: ----- 3(x1) ------ 3(x2) -- 8(x3) ---------------------->

	c: ------------ 7(y5) -------------- 4(y6)----------------->

	d: ------------------- 15(x2,y5) ---- 12(x2,y6) -- 14(x3,y6)
	```
	(For more information: consult the QUARP and/or DREAM academic paper)


	E.g.: `d = a + b + c` (with a, b having `{:g, 0}`, c having `{:t, 0}` and the resulting d having `[{:g, 0}, {:t, 0}]` for guarantee)
	```
	a: 5(x2) --------------------------------------------- 2(x3)

	b: ------- 3(x1) ---------- 3(x2) --- 8(x3) --------------->

	c: --------------- 7(5) --------------------- 4(6) -------->

	d: ------------------------- 15(x2,5) -------- 12(x2,6) --->
	```

	E.g.: `c = a + b` (with a having `[{:g, 0}, {:t, 0}]`, b having `{:g, 0}` and the resulting c having `[{:g, 0}, {:t, 0}]` for guarantee)
	```
	a: 5(x2,1) ---------------------- 7(x2,2) -------- 6(x2,3)->

	b: ------- 3(x1) ---- 4(x2) --------------- 7(x3) --------->

	c: ------------------- 9(x2,1) --- 11(x2,2) ------- 10(x2,3)
	```
	(with the resulting guarantees of d being: {:g, 0}, {:t, 0})
	"""
	def liftapp({:signal, _, _} = s, func) do
		liftapp([s], func)
	end
	def liftapp(signals, func) do
		inds = 0..(length(signals)-1)

		# Tag each value from an observee with its respective index
		sobss = signals
		|> Enum.map(fn {:signal, sobs, _cgs} -> sobs end)
    tagged = Enum.zip(sobss, inds)
    |> Enum.map(fn {sobs, index} -> 
    	sobs
      #|> Observables.Obs.inspect()
      |> Obs.map(fn msg -> {:newvalue, index, msg} end) end)

    # Create the arguments
		gs = signals
		|> Enum.map(fn {:signal, _sobs, cgs} -> cgs end)
		gmap = inds
		|> Enum.zip(gs)
		|> Map.new
		imap = inds
		|> Enum.map(fn i -> {i, []} end)
		|> Map.new

		# Start our CombineWithGuarantees observable.
    {:ok, pid} = GenObservable.start(CombineWithGuarantees, [imap, gmap])
    # Make the observees send to us.
    tagged |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)
    # Create the continuation.
    cobs = {fn observer -> GenObservable.send_to(pid, observer) end, pid}

    # Apply the function to the combined observable
    aobs = cobs
    |> Obs.map(fn {vals, cxts} -> 
    	{apply(func, vals), cxts} end)

    # Determine the resulting guarantees
    cgs = Guarantee.combine(gs)

    # Apply the appropriate transformations to the contexts
    tobs = cgs
    |> Enum.map(fn cg -> Context.new_context_obs(aobs, cg) end)
    |> Obs.zip_n
    robs = aobs
    |> Obs.zip(tobs)
    |> Obs.map(fn {{v, cxs}, ts} -> 
    	tslist = Tuple.to_list(ts)
    	new_cxs = Context.transform(cxs, tslist, cgs)
    	{v, new_cxs} end)

    {:signal, robs, cgs}
	end

	@doc """
	Lifts and applies a function that operates on lists of variable size
	to a list of signals that can be subject to change.

	Takes:
	* A list of signals, each carrying the same guarantee g (can be plural).
	* A higher order signal carrying new signals of guarantee g.
	* A function operating on lists of any size.

	E.g.: `b = List.sum(as) / length(as)` (with all a's having `{:fu, _}` for guarantee) and h a signal carrying new signals.
	```
	h : ----------------- a3 --------------------- a4 -------->

	a1: 5 ------------------------------///////////////////////

	a2: ------------- 3 ----------------------- 6 ------------>

	a3: //////////////////------ 7 --------------------------->

	a4: ////////////////////////////////////////////---- 2 --->

	...

	b : -------------- 4 -------- 5 ------------ 6 ------ 5 -->
	```
	"""
	def liftapp_var([{:signal, _, cgs} | _]=ss, {:signal, hobs, _}, func) do
		inds = 0..(length(ss)-1)

		# Tag each value from an observee with its respective index
		tobss = ss
		|> Stream.map(fn {:signal, sobs, _cgs} -> sobs end)
    |> Stream.zip(inds)
    |> Enum.map(fn {sobs, ind} -> 
    	sobs
      |> Obs.map(fn msg -> {:newvalue, ind, msg} end) end)

    # Unwrap each signal from the higher-order signal and tag it with :newsignal.
    {thobs_f, thobs_p} = hobs
    |> Obs.map(fn {s, _cg} -> {:newsignal, s} end)

    # Create the arguments
		gs = ss
		|> Enum.map(fn {:signal, _sobs, cgs} -> cgs end)
		gmap = inds
		|> Enum.zip(gs)
		|> Map.new
		qmap = inds
		|> Enum.map(fn i -> {i, []} end)
		|> Map.new
		imap = tobss
		|> Stream.map(fn {_f, pid} -> pid end)
		|> Enum.zip(inds)
		|> Map.new

		# Start our CombineVarWithGuarantees observable.
    {:ok, pid} = GenObservable.start(CombineVarWithGuarantees, [qmap, gmap, imap, thobs_p])
    # Make the observees send to us.
    tobss |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)
    # Make the higher order observable send to us
    thobs_f.(pid)
    # Create the continuation.
    cobs = {fn observer -> GenObservable.send_to(pid, observer) end, pid}

    # Apply the function to the combined observable
    aobs = cobs
    |> Obs.map(fn {vals, cxts} -> 
    	{func.(vals), cxts} end)

    # Apply the appropriate transformations to the contexts
    tobs = cgs
    |> Enum.map(fn cg -> Context.new_context_obs(aobs, cg) end)
    |> Obs.zip_n
    robs = aobs
    |> Obs.zip(tobs)
    |> Obs.map(fn {{v, cxs}, ts} -> 
    	tslist = Tuple.to_list(ts)
    	new_cxs = Context.transform(cxs, tslist, cgs)
    	{v, new_cxs} end)

    {:signal, robs, cgs}
	end

  @doc """
  Gets a signal from the registry by its name.
  """
  def signal(name) do
    {:ok, signal} = Registry.get_signal(name)
    signal
  end

  @doc """
  Publishes a signal by registering it in the registry.
  """
	def register(signal, name) do
		Registry.add_signal(signal, name)
    signal
	end

  @doc """
  Unregisters a signal from the registry by its name.
  """
  def unregister(name) do
    Registry.remove_signal(name)
  end

	@doc """
	Inspects the given signal by printing its output values to the console.
	"""
	def inspect({:signal, sobs, cgs}) do
		sobs
		|> Obs.inspect
		{:signal, sobs, cgs}
	end

end