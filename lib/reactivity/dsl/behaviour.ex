defmodule Reactivity.DSL.Behaviour do
  @moduledoc """
  The DSL for distributed reactive programming,
  specifically, operations applicable to Behaviours.
  """
  alias Reactivity.DSL.SignalObs, as: Sobs
  alias Reactivity.DSL.Signal, as: Signal
  alias ReactiveMiddleware.Registry
  alias Observables.Obs

  require Logger

  @doc """
  Checks if the given argument is a Behaviour.
  """
  def is_behaviour?({:behaviour, _sobs, _gs}), do: true
  def is_behaviour?(_o), do: false

  @doc """
  Creates a Behaviour from a plain Observable.

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

    b = {:behaviour, sobs, []}
    case g do
      nil -> b
      _   -> b |> Signal.add_guarantee(g)
    end
  end

  @doc """
  Creates a Behaviour from a Signal Observable, tags it with the given guarantees.

  The assumption here is that the contexts of the Observable have already been attached.
  The primitive can be used for Guarantees with non-obvious contexts (other than e.g. counters)
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
    {:behaviour, sobs, gs}
  end

  @doc """
  Returns the current value of the Behaviour.
  """
  def evaluate({:behaviour, sobs, _gs}) do
    case Obs.last(sobs) do
      nil     -> nil
      {v, _c} -> v
    end
  end

  @doc """
  Transforms a Behaviour into an Event Stream.
  """
  def changes({:behaviour, sobs, gs}) do
    {:event_stream, sobs, gs}
  end

  @doc """
  Switches from an intial Behaviour to newly supplied Behaviours.

  Takes an initial Behaviour and a higher-order Event Stream carrying Behaviours.
  Returns a Behaviour that is at first equal to the initial Behaviour.
  Each time the Event Stream emits a new Behaviour,
  the returned Behaviour switches to this new Behaviour.

  Requires that all Behaviours have the same set of consistency guarantees.
  """
  def switch({:behaviour, b_sobs, gs}, {:event_stream, es_sobs, _}) do
    switch_obs =
      es_sobs
      |> Obs.map(fn {{:behaviour, obs, _}, _gs} -> obs end)

    robs = Obs.switch_repeat(b_sobs, switch_obs)
    {:behaviour, robs, gs}
  end

  @doc """
  Switches from one Behaviour to another on an event occurrence.

  Takes a two Behaviours and an Event Stream.
  Returns a Behaviour that is equal to the first Behaviour until the an event occurs,
  at which point the resulting Behaviour switches to the second Behaviour.
  The value of the event is not relevant.

  Requires that both Behaviours have the same set of consistency guarantees.
  """
  def until({:behaviour, b_sobs1, gs1}, {:behaviour, b_sobs2, _gs2}, {:event_stream, es_sobs, _gse}) do
    robs = Obs.until_repeat(b_sobs1, b_sobs2, es_sobs)
    {:behaviour, robs, gs1}
  end
end
