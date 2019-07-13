defmodule Reactivity.Quality.Guarantee do
  @moduledoc """
  Essential operations on guarantees.
  """

  @doc """
  Combines lists of consistency guarantees.
  """
  def combine(gss) do
    gss
    |> List.flatten()
    |> Enum.group_by(fn {g, _m} -> g end)
    |> Map.values()
    |> Enum.map(fn gs ->
      Enum.min_by(gs, fn {_g, m} -> m end)
    end)
    |> List.flatten()
  end
end
