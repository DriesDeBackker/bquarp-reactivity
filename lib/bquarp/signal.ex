defmodule BQuarp.Signal do
	alias BQuarp.CombineWithGuarantees
	alias BQuarp.Context
	alias BQuarp.Guarantee
	alias BQuarp.SignalObs, as: Sobs

	alias Observables.Obs
  alias Observables.GenObservable

  require Logger

	@doc """
	Creates a signal from a plain observable.
	Attaches the given consistency guarantee to it if provided,
	otherwise attaches :fu as the default consistency guarantee
	(fifo with update semantics: one could consider this to be 'no guarantee')
	"""
	def from_obs(obs, cg \\ {:fu, 0}) do
		sig_obs = obs
		|> Sobs.from_obs
		{:signal, sig_obs, []}
		|> add_guarantee(cg)
	end

	@doc """
	Transforms a signal into a plain observable.
	"""
	def to_obs({:signal, obs, _cgs}) do
		obs
		|> Sobs.to_plain_obs
	end

	@doc """
	Attaches a new consistency guarantee to the signal.
	The signal may already possess a consistency guarantee.
	"""
	def add_guarantee({:signal, obs, cgs}, cg) do
		new_obs = obs
		|> Sobs.add_context(cg)
		{:signal, new_obs, cgs ++ [cg]}
	end

	@doc """
	Sets the given consistency guarantee as the only guarantee for the given signal.

	This can be considered the creation of a new source signal
	from another signal in a stratified dependency graph.
	"""
	def set_guarantee({:signal, obs, _cgs}, cg) do
		new_obs = obs
		|> Sobs.set_context(cg)
		{:signal, new_obs, [cg]}
	end

	@doc """
	Returns the guarantees of the given signal.
	"""
	def guarantees({:signal, obs, cgs}), do: cgs

	@doc """
	Checks if the given signal carries the given guarantee.
	"""
	def carries_guarantee?({:signal, _obs, cgs}, cg) do
		cgs
		|> Enum.any?(fn x -> x == cg end)
	end

	@doc """
	Removes the given guarantee from the given signal if present.
	Leaves the signal alone otherwise.
	"""
	def remove_guarantee({:signal, obs, cgs}, {cgt, _cgm}) do
		remove_guarantee({:signal, obs, cgs}, cgt)
	end
	def remove_guarantee({:signal, obs, cgs}, cgt) do
		i = cgs
		|> Enum.find_index(fn {xt, _xm} -> cgt == xt end)
		new_cgs = cgs
		|> List.delete_at(i)
		new_obs = obs
		|> Sobs.remove_context(i)
		{:signal, new_obs, new_cgs}
	end

	@doc """
	Keeps the given guarantee as the only guarantee of the given signal.
	Removes all other guarantees.
	"""
	def keep_guarantee({:signal, obs, cgs}, {cgt, _cgm}) do
		keep_guarantee({:signal, obs, cgs}, cgt)
	end
	def keep_guarantee({:signal, obs, cgs}, cgt) do
		i = cgs
		|> Enum.find_index(fn {xt, _xm} -> cgt == xt end)
		cg = cgs
		|> Enum.at(i)
		new_cgs = [cg]
		new_obs = obs
		|> Sobs.keep_context(i)
		{:signal, new_obs, new_cgs}
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
	def filter({:signal, obs, _cg}, func, new_cg) do
		fobs = obs
		|> Sobs.to_plain_obs
		|> Obs.filter(func)
		|> Sobs.from_obs
		|> Sobs.add_context(new_cg)
		{:signal, fobs, [new_cg]}
	end
	#TODO: rewrite...
	def filter({:signal, obs, cgs}, func) do
		fobs = obs
		|> Obs.filter(fn {v, _cs} -> func.(v) end)
		{:signal, fobs, cgs}
	end

	@doc """
	Merges multiple signals together such that the resulting signal carries the updates of all composed signals.

	If no consistency guarantee is provided, the merge leaves the updates 'as is'.
	A necessary condition for this operation to be valid then is that the givven signals all carry the same guarantee.
	The consequences of using this operator in this way are left to the developer.

	If however a consistency guarantee is provided, this new guarantee is attached to the resulting signal,
	discarding the previous ones. Thus, merging in this way can be considered to be
	the creation of a new source signal for this guarantee in a stratified dependency graph
	"""
	def merge(signals, new_cg) do
		obss = signals
		|> Enum.map(fn {:signal, obs, _cgs} -> obs end)
		mobs = Obs.merge(obss)
		|> Sobs.set_context(new_cg)
		{:signal, mobs, [new_cg]}
	end
	def merge([{:signal, _obs, cgs} | _st] = signals) do
		obss = signals
		|> Enum.map(fn {:signal, o, _c} -> o end)
		mobs = Obs.merge(obss)
		{:signal, mobs, cgs}
	end

	@doc """
  Applies a given procedure to a signal's value and its previous result. 
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end) 
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
  """
	def scan({:signal, obs, cgs}, func, default \\ nil) do
		{vobs, cobs} = obs
		|> Obs.unzip
		svobs = vobs
		|> Obs.scan(func, default)
		nobs = svobs
		|> Obs.zip(cobs)
		{:signal, nobs, cgs}
	end

	@doc """
	Applies a procedure to the values of a signal without changing them.
	Generally used for side effects.
	"""
	def each({:signal, obs, cgs}, proc) do
		{vobs, cobs} = obs
		|> Obs.unzip
		vobs
		|> Obs.each(proc)
		{:signal, obs, cgs}
	end

	@doc """
	Lifts and applies an ordinary function to one or more signals
	Values of the input signals are produced into output using this function
	depending on the consistency guarantees of the signals

	E.g.:
	s1 with {:fu, _}: 5 --------------------------------- 1 -->
	s2 with {:fu, _}: ------------- 3 --------- 5 ------------>
	s3 = s1 + s2 			-------------- 8 --------- 10 ------ 6 ->
		(with {:fu, _})

	E.g.:
	a with {:fu, _}:  5 ---------------------------------- 1 ->
	b with {:fp, _}:  ------------- 3 ---- 5 ----------------->
	c = a + b			    -------------- 8 ---- 10 --------------->
		(with {:fp, _}, {:fu, _})

	E.g.:
	a with {:fp, _}:  5 --------------------------------- 1 -->
	b with {:fp, _}:  ------------- 3 ---- 5 ----------------->
	c = a + b			    -------------- 8 ------------------- 6 ->
		(with {:fp, _})

	E.g.:
	a with {:t, 0}:   5(2) ------- 3(3} ------------ 1(4) ----------->
	b with {:t, 0}:   ------ 4(1) ---------- 5(2) ------------ 3(3)-->
	c = a + b		      ----------------------- 10(2) ------------6(3)->
		(with {:t, 0})

	E.g.:
	a with {:c, 0}:  5(x2,y2) -------------------------------------- 2(x3,y3) ---->
	b with {:c, 0}:  -------- 3(x1) ---- 3(x2) --- 8(x3) --- 7(x4) --------------->
	d = a + b: 	     -------------------- 8(..) --- 13(..) ---12(..)--9(..)------->
		(with {:c, 0})

	E.g.:
	a with {:g, 0}:  5(x2) ------------------------------------------- 2(x3) --->
	b with {:g, 0}:  ------ 3(x1) ------- 3(x2) --- 8(x3) ---------------------->
	c with {:g, 0}:  ------------- 7(y5) ------------------ 4(y6)--------------->
	d = a + b + c: 	 --------------------- 15(x2,y5) --------12(x2,y6)--14(x3,y6)
		(with {:g, 0})

	E.g.:
	TODO: implement it according to these semantics
				(with propagation values catching up once update values received from all)
	a with {:g, 0}:  5(x2) ------------------------------------------- 2(x3) --->
	b with {:g, 0}:  ------ 3(x1) ------- 3(x2) --- 8(x3) ---------------------->
	c with {:t, 0}:  ------------- 7(5) ------------------ 4(6)----------------->
	d = a + b + c: 	 --------------------- 15(x2,5) --------12(x2,6)------------>
		(with {:g, 0}, {:t, 0})

	E.g.:
	TODO: implement it according to these semantics
				(with propagation values catching up once update values received from all)
	a with {:g, 0}, {:t, 0}:  5(x2,1) -------------------- 7(x2,2)-------- 6(x2,3)->
	b with {:g, 0}:  					-------- 3(x1) -- 4(x2) ------------- 7(x3) --------->
	d = a + b: 	     					------------------ 9(x2,1) -- 11(x2,2) ------ 10(x2,3)
		(with {:g, 0}, {:t, 0})
	"""
	def liftapp({:signal, obs, cgs} = s, func) do
		liftapp([s], func)
	end
	def liftapp(signals, func) do
		inds = 0..(length(signals)-1)

		# Tag each value from an observee with its respective index
		obss = signals
		|> Enum.map(fn {:signal, obs, _cgs} -> obs end)
    tagged = Enum.zip(obss, inds)
    |> Enum.map(fn {obs, index} -> 
    	obs
      #|> Observables.Obs.inspect()
      |> Obs.map(fn msg -> {:newvalue, index, msg} end) end)

    # Create the arguments
		gs = signals
		|> Enum.map(fn {:signal, _obs, cgs} -> cgs end)
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
	to a list of signals that may be subject to change.

	Takes
	* A list of signals, each carrying the same guarantee g (can be plural).
	* A higher order signal carrying new signals of guarantee g.
	* A function operating on lists of any size.
	"""
	def liftapp_var([{:signal, obs, cgs} | st]=ss, {:signal, hobs, _} = hos, func) do
		inds = 0..(length(ss)-1)

		# Tag each value from an observee with its respective index
		tobss = ss
		|> Stream.map(fn {:signal, obs, _cgs} -> obs end)
    |> Stream.zip(inds)
    |> Enum.map(fn {obs, ind} -> 
    	obs
      |> Obs.map(fn msg -> {:newvalue, ind, msg} end) end)

    # Unwrap each signal from the higher-order signal and tag it with :newsignal.
    {thobs_f, thobs_p} = hobs
    |> Obs.map(fn {s, cg} -> {:newsignal, s} end)

    # Create the arguments
		gs = ss
		|> Enum.map(fn {:signal, _obs, cgs} -> cgs end)
		gmap = inds
		|> Enum.zip(gs)
		|> Map.new
		qmap = inds
		|> Enum.map(fn i -> {i, []} end)
		|> Map.new
		imap = tobss
		|> Stream.map(fn {f, pid} -> pid end)
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
	Inspects the given signal by printing its output values to the console.
	"""
	def print({:signal, obs, cgs}) do
		obs
		|> Obs.inspect
		{:signal, obs, cgs}
	end

end