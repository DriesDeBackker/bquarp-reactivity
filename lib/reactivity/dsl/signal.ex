defmodule Reactivity.DSL.Signal do
  @moduledoc """
  The DSL for Distributed Reactive Programming,
  specifically, operations applicable to Signals in general (both Behaviours and Event Streams).
  """
  alias Reactivity.Processing.CombineWithGuarantees
  alias Reactivity.Processing.CombineVarWithGuarantees
  alias Reactivity.Quality.Context
  alias Reactivity.Quality.Guarantee
  alias Reactivity.DSL.SignalObs, as: Sobs
  alias Reactivity.DSL.EventStream, as: ES
  alias Reactivity.DSL.Behaviour, as: B
  alias Reactivity.Registry

  alias Observables.Obs
  alias Observables.GenObservable

  require Logger

  def is_signal?(o) do
  	ES.is_event_stream?(o) or B.is_behaviour?(o)
  end

  @doc """
  Transforms a Signal into a plain Observable.

  The Context is stripped from each Signal Message
  """
  def to_plain_obs({_type, sobs, _gs}) do
    sobs
    |> Sobs.to_plain_obs()
  end

  @doc """
  Transforms a Signal into a Signal Observable.

  Both the Value and Context {v, c} of each Signal Message are preserved.
  """
  def to_signal_obs({_type, sobs, _gs}) do
    sobs
  end

  @doc """
  Attaches a new Guarantee to the Signal.

  The Signal may already possess one or more Guarantees.
  The new Guarantee is simply added.
  """
  def add_guarantee({type, sobs, gs}, g) do
    new_sobs =
      sobs
      |> Sobs.add_context(g)

    {type, new_sobs, gs ++ [g]}
  end

  @doc """
  Sets the given Guarantee as the only guarantee for the given Signal.

  This can be considered the creation of a new source Signal
  from another Signal in a stratified dependency graph.
  """
  def set_guarantee({type, sobs, _gs}, g) do
    new_sobs =
      sobs
      |> Sobs.set_context(g)

    {type, new_sobs, [g]}
  end

  @doc """
  Returns the Guarantees of the given Signal.
  """
  def guarantees({_type, _, gs}), do: gs

  @doc """
  Checks if the given Signal carries the given Guarantee (among others, possibly).
  """
  def carries_guarantee?({_type, _sobs, gs}, g) do
    gs
    |> Enum.any?(fn x -> x == g end)
  end

  @doc """
  Removes the given Guarantee from the given Signal.
  Leaves the Signal alone if the Guarantee is not present.
  """
  def remove_guarantee({type, sobs, gs}, {gt, _gm}) do
    remove_guarantee({type, sobs, gs}, gt)
  end

  def remove_guarantee({type, sobs, gs}, gt) do
    i =
      gs
      |> Enum.find_index(fn {xt, _xm} -> gt == xt end)
    new_gs =
      gs
      |> List.delete_at(i)
    new_sobs =
      sobs
      |> Sobs.remove_context(i)

    {type, new_sobs, new_gs}
  end

  @doc """
  Keeps the given Guarantee as the only Guarantee of the given Signal.
  Removes all other Guarantees.
  """
  def keep_guarantee({type, sobs, gs}, {gt, _gm}) do
    keep_guarantee({type, sobs, gs}, gt)
  end

  def keep_guarantee({type, sobs, gs}, gt) do
    i =
      gs
      |> Enum.find_index(fn {xt, _xm} -> gt == xt end)
    g =
      gs
      |> Enum.at(i)
    new_gs = [g]
    new_sobs =
      sobs
      |> Sobs.keep_context(i)

    {type, new_sobs, new_gs}
  end

  @doc """
  Lifts and applies an n-ary primitive function to n Signals.

  Takes:
  * A list of n input Signals, each with an associated set of Guarantees.
  * An n-ary primitive function
  Returns:
  * An output Signal that is the result of the lifting of the primitive function 
    and its subsequent application to the input Signals.

  Output for the resulting Signal is only created if a newly received message from an input Signal can be combined with the rest of the buffer
  under the Guarantees of the different Signals.

  The resulting Guarantees of the output Signal are a combination of the Guarantee sets of the input Signals.

  When combining:
  * Behaviours:
    - The output signal is a Behaviour.
  	- They have their last values kept as state until a more recent one is used.
  	- Each value is regarded as an update that may trigger a new output.
  	- This is similar to 'combineLatest' in Reactive Extensions.
  * With Event Streams:
    - The output Signal is an Event Stream
    - They have their used values kept only until they can be combined, at which point they are removed so they can't be used more than once.
    - Each value is regarded as a time series data point,
      which needs to be combined with corresponding data points in other time series and popagated thereafter
  	- This is similar to 'Zip' in Reactive Extensions.
  * Both Behaviours and Event Streams
    - The output Signal is an Event Stream
  	- New output is triggered by events from the Event Streams.
  	- New values of behaviours are kept as state to be combined with. They will not however trigger an update.
  	- The first value of a Behaviour can however trigger a series of outputs if there is an event history that has been waiting for this value to combine.
  	- This is similar to 'combineLatestSilent' (with buffered propagation) in Reactive Extensions (specifically in the Observables Extended library)

  E.g.: `c = a + b` (with a, b and the resulting c all having Behaviours without guarantee)
  ```
  a: 5 --------------------------------- 1 -->
  b: ------------- 3 --------- 5 ------------>

  c: -------------- 8 --------- 10 ------ 6 ->
  ```

  E.g.: `c = a + b` (with a Behaviour and b an Event Stream, both without Guarantee,
  and the resulting c an Event Stream without, guarantee as well)
  ```	
  a:  5 ------------------------------------ 1
  b:  ------------- 3 ------ 5 -------------->

  c:	-------------- 8 ------ 10 ------------>
  ```

  E.g.: `c = a + b` (with a, b and the resulting c all Event Streams without Guarantee)
  ```
  a: 5 --------------------------------- 1 -->
  b: ------------- 3 ---- 5 ----------------->

  c: -------------- 8 ------------------- 6 ->
  ```

  E.g.: `c = a + b` (with a, b and the resulting c all Event Streams under `{:t, 0}` = strict time-synchronization)
  ```
  a: 5(2) ----------- 3(3} -------------- 1(4) -------------->
  b: ---------- 4(1) ------------ 5(2) -------------- 3(3) -->

  c: ----------------------------- 10(2) --------------6(3) ->
  ```

  E.g.: `c = a + b` (with a, b and the resulting c all Event Streams under `{:t, 1}` = relaxed time-synchronization)
  ```
  a: 5(2) -------------- 3(3} ------------- 1(4) ------------>
  b: ---------- 4(1) -------------- 5(2) ------------- 3(3) ->

  c: ----------- 9(1,2) ------------- 8(2,3) ---------- 4(3,4)
  ```

  E.g.: `c = a + b` (with a, b and the resulting c all Behaviours under `{:c, 0}` = strict causality)
  ```
  a: 5(x2,y2) --------------------------------------- 2(x3,y3)
  b: -------- 3(x1) ---- 3(x2) --- 8(x3) --- 7(x4) ---------->

  c: -------------------- 8(..) --- 13(..) --- 12(..) -- 9(..)
  ```
  (For more information: consult the DREAM academic paper by Salvaneschi et al.)


  E.g.: `d = a + b + c` (with a, b, c and the resulting d Behaviours under `{:g, 0}` = strict glitch freedom)
  ```
  a: 5(x2) ---------------------------------------- 2(x3) --->
  b: ----- 3(x1) ------ 3(x2) -- 8(x3) ---------------------->
  c: ------------ 7(y5) -------------- 4(y6)----------------->

  d: ------------------- 15(x2,y5) ---- 12(x2,y6) -- 14(x3,y6)
  ```
  (For more information: consult the QUARP and/or DREAM academic paper)


  E.g.: `d = a + b + c` (with a, b Behaviours under `{:g, 0}`, c an Event Stream under `{:t, 0}` 
  and the resulting d an Event Stream with `[{:g, 0}, {:t, 0}]` as Guarantees)
  ```
  a: 5(x2) --------------------------------------------- 2(x3)
  b: ------- 3(x1) ---------- 3(x2) --- 8(x3) --------------->
  c: --------------- 7(5) --------------------- 4(6) -------->

  d: ------------------------- 15(x2,5) -------- 12(x2,6) --->
  ```

  E.g.: `c = a + b` (with a an Event Stream under `[{:g, 0}, {:t, 0}]`, b a Behaviour under `{:g, 0}` 
  and the resulting c an Event Stream having `[{:g, 0}, {:t, 0}]` for Guarantees)
  ```
  a: 5(x2,1) ---------------------- 7(x2,2) -------- 6(x2,3)->
  b: ------- 3(x1) ---- 4(x2) --------------- 7(x3) --------->

  c: ------------------- 9(x2,1) --- 11(x2,2) ------- 10(x2,3)
  ```
  """
  def liftapp({_type, _sobs, _gs} = signal, func) do
    liftapp([signal], func)
  end

  def liftapp(signals, func) do
    inds = 0..(length(signals) - 1)

    # Tag each value from an observee with its respective index
    sobss =
      signals
      |> Enum.map(fn {_type, sobs, _gs} -> sobs end)
    tagged =
      Enum.zip(sobss, inds)
      |> Enum.map(fn {sobs, index} ->
        sobs
        # |> Observables.Obs.inspect()
        |> Obs.map(fn msg -> {:newvalue, index, msg} end)
      end)

    # Create the arguments
    gss =
      signals
      |> Enum.map(fn {_type, _sobs, gs} -> gs end)
    gmap =
      inds
      |> Enum.zip(gss)
      |> Map.new()
    imap =
      inds
      |> Enum.map(fn i -> {i, []} end)
      |> Map.new()
    ts =
      signals
      |> Enum.map(fn {t, _, _} -> t end)
    tmap =
      inds
      |> Enum.zip(ts)
      |> Map.new()
    rtype =
      if contains_event_stream(signals) do
        :event_stream
      else
        :behaviour
      end

    # Start our CombineWithGuarantees observable.
    {:ok, pid} = GenObservable.start(CombineWithGuarantees, [imap, tmap, gmap, rtype])
    # Make the observees send to us.
    tagged |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)
    # Create the continuation.
    cobs = {fn observer -> GenObservable.send_to(pid, observer) end, pid}

    # Apply the function to the combined observable
    aobs =
      cobs
      |> Obs.map(fn {vals, cxts} ->
        {apply(func, vals), cxts}
      end)

    # Determine the resulting guarantees
    gs = Guarantee.combine(gss)
    # Establish the resulting observable
    robs = 
      case gs do
        [] -> 
          aobs
        _  -> 
          # Apply the appropriate transformations to the contexts
          tobs =
            gs
            |> Enum.map(fn g -> Context.new_context_obs(aobs, g) end)
            |> Obs.zip_n()
          aobs
          |> Obs.zip(tobs)
          |> Obs.map(
            fn {{v, cxs}, ts} ->
              tslist = Tuple.to_list(ts)
              new_cxs = Context.transform(cxs, tslist, gs)
              {v, new_cxs}
            end)
      end

    {rtype, robs, gs}
  end

  defp contains_event_stream([]), do: false
  defp contains_event_stream([{:event_stream, _, _} | _st]), do: true
  defp contains_event_stream([{:behaviour, _, _} | st]), do: contains_event_stream(st)

  @doc """
  Lifts a primitive function that operates on lists of any size and applies it to a list of Signals
  (either all Event Streams or all Behaviours), which can be subject to change as Signals drop out 
  and new ones are supplied by a higher-order Event Stream.

  Takes:
  	* A list of Signals, each carrying the same Guarantees gs.
  	* A higher-order Event Stream carrying new Signals with Guarantees gs.
  	* A function operating on lists of values of any size.
  Returns
  * An output Signal that is the result of the lifting of the primitive function 
    and its subsequent application to the input Signals.
    The output Signal has the same type as the input Signals (either Behaviour or Event Stream)

  For behaviours:
  E.g.: `br = List.sum(bs) / length(bs)` (without Guarantee)
  and eh a higher-order Event Stream carrying new Behaviours.
  ```
  eh: ----------------- b3 --------------------- b4 -------->
  b1: 5 ------------------------------///////////////////////
  b2: ------------- 3 ----------------------- 5 ------------>
  b3: //////////////////------ 7 --------------------------->
  b4: ////////////////////////////////////////////---- 3 --->
  ...
  br :-------------- 4 -------- 5 ------------ 6 ------ 5 -->
  ```

  For event streams:
  E.g.: `er = List.sum(es) / length(es)` (without Guarantee)
  and eh a higher-order Event Stream carrying new Event Streams.
  ```
  eh: ----------------- e3 --------------------- e4 -------------->
  e1: 5 ---------------------------- 4 --- 5 -/////////////////////
  e2: ------------- 3 ------------ 4 ----------- 5 ----------- 4 ->
  e3: //////////////////------ 7 ------------ 5 -------- 4 ------->
  e4: ///////////////////////////////////////////////////////---- 1
  ...
  er :-------------- 4 ------------- 5 --------- 5 ------ 5 ----- 3
  ```
  """
  def liftapp_var([{type, _, gs} | _] = ss, {:event_stream, hobs, _}, func) do
    inds = 0..(length(ss) - 1)

    # Tag each value from an observee with its respective index
    tobss =
      ss
      |> Stream.map(fn {_type, sobs, _gs} -> sobs end)
      |> Stream.zip(inds)
      |> Enum.map(fn {sobs, ind} ->
        sobs
        |> Obs.map(fn msg -> {:newvalue, ind, msg} end)
      end)

    # Unwrap each signal from the higher-order event-stream and tag it with :newsignal.
    {thobs_f, thobs_p} =
      hobs
      |> Obs.map(fn {s, _g} -> {:newsignal, s} end)

    # Create the arguments
    gss =
      ss
      |> Enum.map(fn {_type, _sobs, gs} -> gs end)
    gmap =
      inds
      |> Enum.zip(gss)
      |> Map.new()
    qmap =
      inds
      |> Enum.map(fn i -> {i, []} end)
      |> Map.new()
    imap =
      tobss
      |> Stream.map(fn {_f, pid} -> pid end)
      |> Enum.zip(inds)
      |> Map.new()

    # Start our CombineVarWithGuarantees observable.
    {:ok, pid} = GenObservable.start(CombineVarWithGuarantees, [qmap, gmap, type, imap, thobs_p])
    # Make the observees send to us.
    tobss |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)
    # Make the higher order observable send to us
    thobs_f.(pid)
    # Create the continuation.
    cobs = {fn observer -> GenObservable.send_to(pid, observer) end, pid}

    # Apply the function to the combined observable
    aobs =
      cobs
      |> Obs.map(fn {vals, cxts} ->
        {func.(vals), cxts}
      end)

    # Establish the resulting observable
    robs = 
      case gs do
        [] -> 
          aobs
        _  -> 
          # Apply the appropriate transformations to the contexts
          tobs =
            gs
            |> Enum.map(fn g -> Context.new_context_obs(aobs, g) end)
            |> Obs.zip_n()
          aobs
          |> Obs.zip(tobs)
          |> Obs.map(
            fn {{v, cxs}, ts} ->
              tslist = Tuple.to_list(ts)
              new_cxs = Context.transform(cxs, tslist, gs)
              {v, new_cxs}
            end)
      end

    {type, robs, gs}
  end

  @doc """
  Gets a Signal from the Registry by its name.
  """
  def signal(name) do
    {:ok, signal} = Registry.get_signal(name)
    signal
  end

  @doc """
  Publishes a Signal by registering it in the Registry.
  """
  def register(signal, name) do
    Registry.add_signal(signal, name)
    signal
  end

  @doc """
  Unregisters a Signal from the Registry by its name.
  """
  def unregister(name) do
    Registry.remove_signal(name)
  end

  @doc """
  Inspects the given Signal by printing its output Values to the console.
  """
  def inspect({type, sobs, cgs}) do
    sobs
    |> Obs.inspect()

    {type, sobs, cgs}
  end
end
