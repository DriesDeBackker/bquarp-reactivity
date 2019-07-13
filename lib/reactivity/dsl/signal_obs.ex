defmodule Reactivity.DSL.SignalObs do
  @moduledoc false
  alias Observables.Obs
  alias Reactivity.Quality.Context

  @doc """
  Turns a plain Observable into a Signal Observable

  Wraps each of its Values v into a tuple `{v, []}`,
  the empty list being a list of potential Contexts.
  """
  def from_plain_obs(obs) do
    obs
    |> Obs.map(fn v -> {v, []} end)
  end

  @doc """
  Turns a Signal Observable back into a plain Observable

  Unboxes each of its Values v from its encompassing Message `{v, c}`,
  effectively stripping it from any associated Contexts it might have.
  """
  def to_plain_obs(sobs) do
    {vobs, _cobs} =
      sobs
      |> Obs.unzip()

    vobs
  end

  @doc """
  Transforms a Signal Observable to an Observable carrying only its Contexts
  """
  def to_context_obs(sobs) do
    {_vobs, cobs} =
      sobs
      |> Obs.unzip()

    cobs
  end

  @doc """
  Adds the appropriate Contexts for the given Guarantee to a Signal Observable.

  The Context is added to the back of the list of Contexts `[c]`
  that is part of the Message tuple `{v, [c]}` emitted by a Signal Observable.
  """
  def add_context(sobs, cg) do
    acobs = Context.new_context_obs(sobs, cg)
    {vobs, cobs} =
      sobs
      |> Obs.unzip()
    ncobs =
      cobs
      |> Obs.zip(acobs)
      |> Obs.map(fn {pc, ac} -> pc ++ [ac] end)

    Obs.zip(vobs, ncobs)
  end

  @doc """
  Removes a Context from a Signal Observable by its index.
  """
  def remove_context(sobs, i) do
    sobs
    |> Obs.map(fn {v, cs} ->
      new_cs =
        cs
        |> List.delete_at(i)

      {v, new_cs}
    end)
  end

  @doc """
  Removes all Contexts from the Signal Observable, safe for the one at the given index.
  """
  def keep_context(sobs, i) do
    sobs
    |> Obs.map(fn {v, cs} ->
      c =
        cs
        |> Enum.at(i)

      new_cs = [c]
      {v, new_cs}
    end)
  end

  @doc """
  Removes all Contexts from the Signal Observable.
  """
  def clear_context(sobs) do
    sobs
    |> Obs.map(fn {v, _c} -> {v, []} end)
  end

  @doc """
  Sets the appropriate Contexts of a Signal Observable for the given Guarantee.
  Replaces all existing Contexts.
  """
  def set_context(sobs, cg) do
    sobs
    |> clear_context
    |> add_context(cg)
  end
end
