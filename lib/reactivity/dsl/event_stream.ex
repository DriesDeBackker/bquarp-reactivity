defmodule Reactivity.DSL.EventStream do
  @moduledoc """
  The DSL for distributed reactive programming,
  specifically, operations applicable to Event Streams.
  """
  alias Reactivity.DSL.SignalObs, as: Sobs
  alias Reactivity.DSL.Signal, as: Signal
  alias Reactivity.Registry
  alias Observables.Obs

  require Logger

  @doc """
  Checks if the given argument is an Event Stream.
  """
  def is_event_stream?({:event_stream, _sobs, _gs}), do: true
  def is_event_stream?(_o), do: false

  @doc """
  Creates an Event Stream from a plain Observable.

  Attaches the given Guarantee to it if provided.
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
  Creates an Event Stream from a Signal Observable and tags it with the given guarantees.

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
  Transforms the Event Stream into a Behaviour.
  """
  def hold({:event_stream, sobs, cgs}) do
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
  def filter({:event_stream, sobs, _cg}, pred, new_cg) do
    fobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.filter(pred)
      |> Sobs.from_plain_obs()
      |> Sobs.add_context(new_cg)

    {:event_stream, fobs, [new_cg]}
  end

  def filter({:event_stream, sobs, cgs}, pred) do
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
  def merge(ess, new_g) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _gs} -> sobs end)
    mobs =
      Obs.merge(sobss)
      |> Sobs.set_context(new_g)

    {:event_stream, mobs, [new_g]}
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
  def rotate(ess, new_cg) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _cgs} -> sobs end)
    robs =
      Obs.rotate(sobss)
      |> Sobs.set_context(new_cg)

    {:event_stream, robs, [new_cg]}
  end
  def rotate([{:event_stream, _obs, cgs} | _st] = ess) do
    sobss =
      ess
      |> Enum.map(fn {:event_stream, sobs, _cgs} -> sobs end)
    robs = Obs.rotate(sobss)

    {:event_stream, robs, cgs}
  end

  @doc """
  Applies a given procedure to the values of an Event Stream and its previous result. 
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end)
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
  """
  def scan({:event_stream, sobs, cgs}, func, default \\ nil) do
    svobs =
      sobs
      |> Sobs.to_plain_obs()
      |> Obs.scan(func, default)
    cobs =
      sobs
      |> Sobs.to_context_obs()
    nobs =
      svobs
      |> Obs.zip(cobs)

    {:event_stream, nobs, cgs}
  end

  @doc """
  Applies a procedure to the values of an Event Stream without changing them.
  Generally used for side effects.
  """
  def each({:event_stream, sobs, cgs}, proc) do
    sobs
    |> Sobs.to_plain_obs()
    |> Obs.each(proc)

    {:event_stream, sobs, cgs}
  end
end
