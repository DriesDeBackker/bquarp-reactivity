defmodule Reactivity.DSL.EventStream do
  @moduledoc """
  The DSL for distributed reactive programming,
  specifically, operations applicable to Event Streams.
  """
  alias Reactivity.DSL.SignalObs, as: Sobs
  alias Reactivity.DSL.Signal, as: Signal
  alias ReactiveMiddleware.Registry
  alias Observables.Obs

  require Logger

  @doc """
  Checks if the given object `o` is an Event Stream.
  """
  def is_event_stream?({:event_stream, _sobs, _gs}=_o), do: true
  def is_event_stream?(_o), do: false

  @doc """
  Creates an Event Stream from a plain Observable `obs`.

  Attaches the given Guarantee `g` to it if provided.
  Otherwise attaches the globally defined Guarantee,
  which is FIFO (the absence of any Guarantee) by default.
  """
  def from_plain_obs(obs) do
    g = Registry.get_guarantee()
    from_plain_obs(obs, g)
  end
  def from_plain_obs(obs, g) do
    sobs =
      obs
      |> Sobs.from_plain_obs()

    es = {:event_stream, sobs, []}
    case g do
      nil -> es
      _   -> es |> Signal.add_guarantee(g)
    end
  end

  @doc """
  Creates an Event Stream from a Signal Observable `sobs` and tags it with the given guarantees `gs`.

  The assumption here is that the contexts of the Signal Observable have already been attached.
  The primitive can be used for Guarantees with non-obvious Contexts (other than e.g. counters)
  the developer might come up with.

  Attaches the given Guarantee to it if provided without changing the context.
  Otherwise attaches the globally defined Guarantee,
  which is FIFO (the absence of any Guarantee) by default.
  """
  def from_signal_obs(sobs) do
    g = Registry.get_guarantee()
    gs = 
      case g do
        nil -> []
        _   -> [g]
      end
    from_signal_obs(sobs, gs)
  end
  def from_signal_obs(sobs, gs) do
    {:event_stream, sobs, gs}
  end

  @doc """
  Transforms the Event Stream `es` into a Behaviour by adhering to its latest change.
  """
  def hold({:event_stream, sobs, cgs}=_es) do
    {:behaviour, sobs, cgs}
  end

  @doc """
  Filters out the Event Streams values that do not satisfy the given predicate.

  The expected function should take one argument, the value of an Observable and return a Boolean:
  true if the value should be produced, false if the value should be discarded.

  If no Guarantee is provided, the merge does not alter the Event Stream Messages.
  The consequences of using this operator in this way are left to the developer.

  If however a Guarantee is provided, it is attached to the resulting Event Stream as its new Guarantee,
  replacing any previous ones. This is reflected in the Message Contexts.
  Thus, filtering in this way can be considered to be the creation of a new source Signal 
  with the given Guarantee in a stratified dependency graph.
  """
  def filter({:event_stream, sobs, _cg}=_es, pred, g) do
    fobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.filter(pred)
      |> Sobs.from_plain_obs()
      |> Sobs.add_context(g)

    {:event_stream, fobs, [g]}
  end

  def filter({:event_stream, sobs, cgs}=_es, pred) do
    fobs =
      sobs
      |> Obs.filter(fn {v, _cs} -> pred.(v) end)

    {:event_stream, fobs, cgs}
  end

  @doc """
  Merges multiple Event Streams together
  The resulting Event Stream carries the events of all composed Event Streams as they arrived.

  If no Guarantee is provided, the merge does not alter the Event Stream Messages.
  A necessary condition for this operation to be valid then is that the given Event Streams all carry the same Guarantees.
  The consequences of using this operator in this way are left to the developer.

  If however a Guarantee is provided, it is attached to the resulting Event Stream as its new Guarantee,
  replacing any previous ones. This is reflected in the Message Contexts.
  Thus, merging in this way can be considered to be the creation of a new source Signal 
  with the given Guarantee in a stratified dependency graph.
  """
  def merge(ess, g) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _gs} -> sobs end)
    mobs =
      Obs.merge(sobss)
      |> Sobs.set_context(g)

    {:event_stream, mobs, [g]}
  end
  def merge([{:event_stream, _obs, gs} | _st] = signals) do
    sobss =
      signals
      |> Enum.map(fn {:event_stream, sobs, _gs} -> sobs end)
    mobs = Obs.merge(sobss)

    {:event_stream, mobs, gs}
  end

  @doc """
  Merges multiple Event Streams together
  The resulting Event Stream carries the events of all composed Event Streams in a round-robin fashion.

  Should not be used for Event Streams with known discrepancies in event occurrence frequency,
  since messages will accumulate and create a memory leak.

  If no Guarantee is provided, the merge does not alter the Event Stream Messages.
  A necessary condition for this operation to be valid then is that the given Event Streams all carry the same Guarantees.
  The consequences of using this operator in this way are left to the developer.

  If however a Guarantee is provided, it is attached to the resulting Event Stream as its new Guarantee,
  replacing any previous ones. This is reflected in the Message Contexts.
  Thus, merging in this way can be considered to be the creation of a new source Signal 
  with the given Guarantee in a stratified dependency graph.
  """
  def rotate(ess, g) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _cgs} -> sobs end)
    robs =
      Obs.rotate(sobss)
      |> Sobs.set_context(g)

    {:event_stream, robs, [g]}
  end
  def rotate([{:event_stream, _obs, cgs} | _st] = ess) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _cgs} -> sobs end)
    robs = Obs.rotate(sobss)

    {:event_stream, robs, cgs}
  end

  @doc """
  Applies a given binary function `f` to the values of an Event Stream `es` and its previous result. 
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end)
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
  """
  def scan({:event_stream, sobs, cgs}=_es, f, default \\ nil) do
    svobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.scan(f, default)
    cobs =
      sobs
      |> Sobs.to_context_obs()
    nobs =
      svobs
      |> Obs.zip(cobs)

    {:event_stream, nobs, cgs}
  end

  @doc """
  Delays each produced item by the given interval.
  """
  def delay({:event_stream, sobs, cgs}=_es, interval) do
    dobs = 
      sobs
      |> Obs.delay(interval)
    {:event_stream, dobs, cgs}
  end

  @doc """
  Filters out values of an Event Stream `es` that have already been produced at some point.

  If no Guarantee is provided, it does not alter the Event Stream Messages.
  The consequences of using this operator in this way are left to the developer.

  If however a Guarantee `g` is provided, it is attached to the resulting Event Stream as its new Guarantee,
  replacing any previous ones. This is reflected in the Message Contexts.
  This can be considered to be the creation of a new source Signal 
  with the given Guarantee in a stratified dependency graph.
  """
  def distinct({:event_stream, sobs, _cgs}=_es, g) do
    dsobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.distinct(fn(x,y) -> x == y end)
      |> Sobs.from_plain_obs()
      |> Sobs.add_context(g)

    {:event_stream, dsobs, [g]}
  end

 def distinct({:event_stream, sobs, cgs}=_es) do
    dsobs =
      sobs
      |> Obs.distinct(fn({v1, _cs1}, {v2, _cs2}) -> v1 == v2 end)

    {:event_stream, dsobs, cgs}
  end

  @doc """
  Filters out values of an Event Stream `es` that are equal to the most recently produced value.

  If no Guarantee is provided, it does not alter the Event Stream Messages.
  The consequences of using this operator in this way are left to the developer.

  If however a Guarantee is provided, it is attached to the resulting Event Stream as its new Guarantee,
  replacing any previous ones. This is reflected in the Message Contexts.
  This can be considered to be the creation of a new source Signal 
  with the given Guarantee in a stratified dependency graph.
  """
  def novel({:event_stream, sobs, _cgs}=_es, g) do
    nsobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.novel(fn(x,y) -> x == y end)
      |> Sobs.from_plain_obs()
      |> Sobs.add_context(g)

    {:event_stream, nsobs, [g]}
  end

 def novel({:event_stream, sobs, cgs}=_es) do
    nsobs =
      sobs
      |> Obs.novel(fn({v1, _cs1}, {v2, _cs2}) -> v1 == v2 end)

    {:event_stream, nsobs, cgs}
  end

  @doc """
  Applies a procedure to the values of an Event Stream `es` without changing them.
  Generally used for side effects.
  """
  def each({:event_stream, sobs, cgs}=_es, proc) do
    sobs
    |> Sobs.to_plain_obs()
    |> Obs.each(proc)

    {:event_stream, sobs, cgs}
  end

  @doc """
  Switches from an intial Event Stream to newly supplied Behaviours.

  Takes an initial Event Stream `es` and a higher-order Event Stream `he` carrying Event Streams.
  Returns an Event Stream that is at first equal to the initial Event Stream.
  Each time the higher order Event Stream emits a new Event Stream,
  the returned Event Stream switches to this new Event Stream.

  Requires that all Event Streams carry values of the same type 
  and have the same set of consistency guarantees.
  """
  def switch({:event_stream, es_sobs, gs}=_es, {:event_stream, hes_sobs, _}=_he) do
    switch_obs =
      hes_sobs
      |> Obs.map(fn {{:event_stream, obs, _}, _gs} -> obs end)

    robs = Obs.switch(es_sobs, switch_obs)
    {:event_stream, robs, gs}
  end

  @doc """
  Switches from one Event Stream to another on an event occurrence.

  Takes three Event Streams.
  Returns an Event Stream that emits the events of the first Event Stream `es1` until an event on the third Event Stream `es` occurs,
  at which point the resulting Event Stream switches to the second Event Stream `es2`.
  The value of the switching event is irrelevant.

  Requires that both Event Streams have the same set of consistency guarantees
  and carry values of the same type.
  """
  def until({:event_stream, es_sobs1, gs1}=_es1, {:event_stream, es_sobs2, _gs2}=_es2, {:event_stream, es_sobs, _gse}=_es) do
    robs = Obs.until(es_sobs1, es_sobs2, es_sobs)
    {:event_stream, robs, gs1}
  end
end
