defmodule Reactivity.Processing.CombineVarWithGuarantees do
  @moduledoc false
  use Observables.GenObservable
  alias Observables.Obs
  alias Reactivity.Processing.Matching

  require Logger

  def init([qmap, gmap, type, imap, hosp]) do
    Logger.debug("CombineVarWithGuarantee: #{inspect(self())}")
    # Define the index for the next signal.
    kcounter =
      imap
      |> Map.values()
      |> length

    {is, _qs} =
      qmap
      |> Enum.unzip()

    amap =
      is
      |> Enum.zip(List.duplicate(true, length(is)))
      |> Map.new()

    # hosp: higher order signal pid.
    {:ok, {qmap, gmap, imap, hosp, amap, type, kcounter}}
  end

  # Handle a new signal to listen to.
  def handle_event({:newsignal, signal}, {buffer, gmap, imap, hosp, amap, type, kcounter}) do
    # Tag the new signal with its newly given index so that we can process it properly.
    {_type, obs, gs} = signal

    {t_f, t_pid} =
      obs
      |> Obs.map(fn msg -> {:newvalue, kcounter, msg} end)

    # Make the tagged observable send to us.
    t_f.(self())

    new_buffer =
      buffer
      |> Map.put(kcounter, [])

    new_gmap =
      gmap
      |> Map.put(kcounter, gs)

    new_amap =
      amap
      |> Map.put(kcounter, true)

    new_imap =
      imap
      |> Map.put(t_pid, kcounter)

    new_kcounter = kcounter + 1
    {:novalue, {new_buffer, new_gmap, new_imap, hosp, new_amap, type, new_kcounter}}
  end

  def handle_event({:newvalue, index, msg}, {buffer, gmap, imap, hosp, amap, type, kcounter}) do
    updated_buffer = %{buffer | index => Map.get(buffer, index) ++ [msg]}

    is =
      imap
      |> Map.keys()

    tmap =
      is
      |> Enum.zip(List.duplicate(type, length(is)))

    case Matching.match(updated_buffer, msg, index, tmap, gmap) do
      :nomatch ->
        {:novalue, {updated_buffer, gmap, imap, hosp, amap, type, kcounter}}

      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} =
          match
          |> Enum.unzip()

        {new_buffer, new_gmap, new_amap} =
          if type == :event_stream do
            remove_empty_dead_queues(new_buffer, gmap, amap)
          else
            {new_buffer, gmap, amap}
          end

        {:value, {vals, contexts}, {new_buffer, new_gmap, imap, hosp, new_amap, type, kcounter}}
    end
  end

  def handle_done(hosp, {buffer, gmap, imap, hosp, amap, type, kcounter}) do
    Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has a dead signal stream, 
  		going on with possibility of termination.")
    {:ok, :continue, {buffer, gmap, imap, nil, amap, type, kcounter}}
  end

  def handle_done(pid, {buffer, gmap, imap, hosp, amap, type, kcounter}) do
    index =
      imap
      |> Map.get(pid)

    new_imap =
      imap
      |> Map.delete(pid)

    new_amap =
      amap
      |> Map.put(index, false)

    {new_buffer, new_gmap, new_amap} =
      if type == :behaviour or
           buffer |> Map.get(index) |> Enum.empty?() do
        {buffer |> Map.delete(index), gmap |> Map.delete(index), amap |> Map.delete(index)}
      else
        {buffer, gmap, new_amap}
      end

    case hosp do
      nil ->
        Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has one dead dependency 
  			and already a dead higher order event stream, going on with possibility of termination.")
        {:ok, :continue, {new_buffer, new_gmap, new_imap, nil, new_amap, type, kcounter}}

      _ ->
        Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has one dead dependency, 
    		but an active higher order event stream, going on without possibility of termination at this point."
        )

        {:ok, :continue, :notermination, 
         {new_buffer, new_gmap, new_imap, hosp, new_amap, type, kcounter}}
    end
  end

  defp remove_empty_dead_queues(buffer, gmap, amap) do
    ris =
      buffer
      |> Stream.filter(fn {i, q} ->
        not (q |> Enum.empty?() and
               amap |> Map.get(i) == false)
      end)
      |> Enum.map(fn {i, _} -> i end)

    new_buffer =
      ris
      |> Enum.zip(
        ris
        |> Enum.map(fn i -> Map.get(buffer, i) end)
      )
      |> Map.new()

    new_gmap =
      ris
      |> Enum.zip(
        ris
        |> Enum.map(fn i -> Map.get(gmap, i) end)
      )
      |> Map.new()

    new_amap =
      ris
      |> Enum.zip(
        ris
        |> Enum.map(fn i -> Map.get(amap, i) end)
      )
      |> Map.new()

    {new_buffer, new_gmap, new_amap}
  end
end
