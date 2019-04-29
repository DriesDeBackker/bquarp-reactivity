defmodule Quality.BQuarp.CombineWithGuarantees do
  @moduledoc false
  use Observables.GenObservable
  alias Quality.BQuarp.Matching
  require Logger

  def init([imap, gmap]) do
    Logger.debug("CombineWithGuarantee: #{inspect(self())}")
    {:ok, {:buffer, imap, :guarantees, gmap}}
  end

  def handle_event({index, msg}, {:buffer, buffer, :guarantees, gs}) do
  	updated_buffer = %{buffer | index => Map.get(buffer, index) ++ [msg]}
  	case Matching.match(updated_buffer, msg, index, gs) do
      :nomatch ->
        {:novalue, {:buffer, updated_buffer, :guarantees, gs}}
      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} = match
        |> Enum.unzip
        {:value, {vals, contexts}, {:buffer, new_buffer, :guarantees, gs}}
  	end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: combinelatestn has one dead dependency, going on.")
    {:ok, :continue}
  end
end