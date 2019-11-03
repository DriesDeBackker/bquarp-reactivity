defmodule Reactivity.Processing.CombineWithGuarantees do
  @moduledoc false
  use Observables.GenObservable
  alias Reactivity.Processing.Matching

  require Logger

  def init([imap, tmap, gmap, rtype]) do
    Logger.debug("CombineWithGuarantee: #{inspect(self())}")
    {:ok, {:buffer, imap, :types, tmap, :guarantees, gmap, :result, rtype}}
  end

  def handle_event({:newvalue, index, msg},
        {:buffer, buffer, :types, tmap, :guarantees, gmap, :result, rtype}) do
    updated_buffer = %{buffer | index => Map.get(buffer, index) ++ [msg]}

    case Matching.match(updated_buffer, msg, index, tmap, gmap) do
      :nomatch ->
        {:novalue, {:buffer, updated_buffer, :types, tmap, :guarantees, gmap, :result, rtype}}

      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} =
          match
          |> Enum.unzip()

        if first_value?(index, buffer) and
             Map.get(tmap, index) == :behaviour and
             rtype == :event_stream do
          Process.send(self(), {:event, {:spit, index}}, [])
        end

        {:value, {vals, contexts},
         {:buffer, new_buffer, :types, tmap, :guarantees, gmap, :result, rtype}}
    end
  end

  def handle_event({:spit, index},
        {:buffer, buffer, :types, tmap, :guarantees, gmap, :result, rtype}) do
    msg =
      buffer
      |> Map.get(index)
      |> List.first()

    case Matching.match(buffer, msg, index, tmap, gmap) do
      :nomatch ->
        {:novalue, {:buffer, buffer, :types, tmap, :guarantees, gmap, :result, rtype}}

      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} =
          match
          |> Enum.unzip()

        Process.send(self(), {:event, {:spit, index}}, [])

        {:value, {vals, contexts},
         {:buffer, new_buffer, :types, tmap, :guarantees, gmap, :result, rtype}}
    end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: combinelatestn has one dead dependency, going on.")
    {:ok, :continue}
  end

  defp first_value?(index, buffer) do
    buffer
    |> Map.get(index)
    |> Enum.empty?()
  end
end
