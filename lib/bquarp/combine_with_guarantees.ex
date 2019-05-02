defmodule BQuarp.CombineWithGuarantees do
  @moduledoc false
  use Observables.GenObservable
  alias BQuarp.Matching
  alias BQuarp.Guarantee
  require Logger

  def init([imap, gmap]) do
    Logger.debug("CombineWithGuarantee: #{inspect(self())}")
    {:ok, {:buffer, imap, :guarantees, gmap}}
  end

  def handle_event({:newvalue, index, msg}, {:buffer, buffer, :guarantees, gss}) do
    Logger.debug("The message received: #{inspect msg}")
    Logger.debug("The buffer right now: #{inspect buffer}")
  	updated_buffer = %{buffer | index => Map.get(buffer, index) ++ [msg]}
  	case Matching.match(updated_buffer, msg, index, gss) do
      :nomatch ->
        {:novalue, {:buffer, updated_buffer, :guarantees, gss}}
      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} = match
        |> Enum.unzip
        if first_value?(index, buffer) 
         and update?(index, gss)
         and any_propagate?(gss) do
          Process.send(self(), {:event, {:spit, index}}, [])
        end
        {:value, {vals, contexts}, {:buffer, new_buffer, :guarantees, gss}}
  	end
  end

  def handle_event({:spit, index}, {:buffer, buffer, :guarantees, gss}) do
    Logger.debug("Spitting..")
    msg = buffer
    |> Map.get(index)
    |> List.first
    case Matching.match(buffer, msg, index, gss) do
      :nomatch ->
        {:novalue, {:buffer, buffer, :guarantees, gss}}
      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} = match
        |> Enum.unzip
        Process.send(self(), {:event, {:spit, index}}, [])
        {:value, {vals, contexts}, {:buffer, new_buffer, :guarantees, gss}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: combinelatestn has one dead dependency, going on.")
    {:ok, :continue}
  end

  defp first_value?(index, buffer) do
    buffer
    |> Map.get(index)
    |> Enum.empty?
  end

  defp update?(index, gss) do
    gss
    |> Map.get(index)
    |> Guarantee.semantics
    == :update
  end

  defp any_propagate?(gss) do
    gss
    |> Map.values
    |> Enum.map(fn gs -> Guarantee.semantics(gs) end)
    |> Enum.any?(fn sem -> sem == :propagate end)
  end

end