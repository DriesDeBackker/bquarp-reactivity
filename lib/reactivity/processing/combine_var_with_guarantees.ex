defmodule Reactivity.Processing.CombineVarWithGuarantees do
  @moduledoc false
  use Observables.GenObservable
  alias Observables.Obs
  alias Reactivity.Processing.Matching
  alias Reactivity.Quality.Guarantee
  require Logger

  def init([qmap, gmap, imap, hosp]) do
    Logger.debug("CombineWithGuarantee: #{inspect(self())}")
    # Define the index for the next signal.
    kcounter = imap
    |> Map.values
    |> length
    {is, _qs} = qmap
    |> Enum.unzip
    amap = is
    |> Enum.zip(List.duplicate(true, length(is)))
    |> Map.new
    #hosp: higher order signal pid.
    {:ok, {qmap, gmap, imap, hosp, amap, kcounter}}
  end

  # Handle a new signal to listen to.
  def handle_event({:newsignal, signal}, {buffer, gmap, imap, hosp, amap, kcounter}) do
  	Logger.error("new signal: #{inspect signal}")
  	# Tag the new signal with its newly given index so that we can process it properly.
  	{:signal, obs, gs} = signal
  	{t_f, t_pid} = obs
  	|> Obs.map(fn msg -> {:newvalue, kcounter, msg} end)
  	# Make the tagged observable send to us.
  	t_f.(self())
		new_buffer = buffer
		|> Map.put(kcounter, [])
		new_gmap = gmap
		|> Map.put(kcounter, gs)
		new_amap = amap
		|> Map.put(kcounter, true)
		new_imap = imap
		|> Map.put(t_pid, kcounter)
		new_kcounter = kcounter + 1
		Logger.error("new buffer: #{inspect new_buffer}")
		{:novalue, {new_buffer, new_gmap, new_imap, hosp, new_amap, new_kcounter}}
  end

  def handle_event({:newvalue, index, msg}, {buffer, gmap, imap, hosp, amap, kcounter}) do
  	updated_buffer = %{buffer | index => Map.get(buffer, index) ++ [msg]}
  	Logger.error("received message: #{inspect msg}")
  	Logger.error("updated_buffer: #{inspect updated_buffer}")
  	case Matching.match(updated_buffer, msg, index, gmap) do
      :nomatch ->
      	Logger.error("nomatch")
        {:novalue, {updated_buffer, gmap, imap, hosp, amap, kcounter}}
      {:ok, match, contexts, new_buffer} ->
      	Logger.error("got a match")
        {vals, _contextss} = match
        |> Enum.unzip
        if first_value?(index, buffer)
         and update?(index, gmap)
         and any_propagate?(gmap) do
          Process.send(self(), {:event, {:spit, index, msg}}, [])
        end
        {new_buffer, new_gmap, new_amap} = remove_empty_dead_queues(new_buffer, gmap, amap)
        Logger.error("result: #{inspect vals}")
        {:value, {vals, contexts}, {new_buffer, new_gmap, imap, hosp, new_amap, kcounter}}
  	end
  end

  def handle_event({:spit, index}, {buffer, gmap, imap, hosp, amap, kcounter}) do
    Logger.debug("Spitting...")
    msg = buffer
    |> Map.get(index)
    |> List.first
    case Matching.match(buffer, msg, index, gmap) do
      :nomatch ->
        {:novalue, {buffer, gmap, imap, hosp, amap, kcounter}}
      {:ok, match, contexts, new_buffer} ->
        {vals, _contextss} = match
        |> Enum.unzip
        Process.send(self(), {:event, {:spit, index, msg}}, [])
        {new_buffer, new_gmap, new_amap} = remove_empty_dead_queues(new_buffer, gmap, amap)
        {:value, {vals, contexts}, {new_buffer, new_gmap, imap, hosp, new_amap, kcounter}}
    end
  end

 def handle_done(hosp, {buffer, gmap, imap, hosp, amap, kcounter}) do
  	Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has a dead signal stream, 
  		going on with possibility of termination.")
  	{:ok, :continue, {buffer, gmap, imap, nil, amap, kcounter}}
  end
  def handle_done(pid, {buffer, gmap, imap, hosp, amap, kcounter}) do
  	Logger.error("imap: #{inspect imap}")
  	Logger.error("pid: #{inspect pid}")
  	index = imap
    |> Map.get(pid)
    Logger.error("index: #{inspect index}")
    new_imap = imap
    |> Map.delete(pid)
    new_amap = amap
    |> Map.put(index, false)
    {new_buffer, new_gmap, new_amap} = 
    	if update?(index, gmap) 
    	 or (buffer |> Map.get(index) |> Enum.empty?) do
	    	{(buffer |> Map.delete(index)),
	    	 (gmap |> Map.delete(index)),
	    	 (amap |> Map.delete(index))}
    	else {buffer, gmap, new_amap}
    	end
    case hosp do
    	nil -> 
    		Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has one dead dependency 
  			and already a dead signal stream, going on with possibility of termination.")
  			{:ok, :continue, {new_buffer, new_gmap, new_imap, nil, new_amap, kcounter}}
  		_ -> 
  			Logger.debug("#{inspect(self())}: CombineVarWithGuarantees has one dead dependency, 
    		but an active signal stream, going on without possibility of termination at this point.")
    		{:ok, :continue, :notermination, {new_buffer, new_gmap, new_imap, hosp, new_amap, kcounter}}
    end
  end

  defp first_value?(index, buffer) do
    buffer
    |> Map.get(index)
    |> Enum.empty?
  end

  defp update?(index, gmap) do
    gmap
    |> Map.get(index)
    |> Guarantee.semantics
    == :update
  end

  defp any_propagate?(gmap) do
    gmap
    |> Map.values
    |> Enum.map(fn gs -> Guarantee.semantics(gs) end)
    |> Enum.any?(fn sem -> sem == :propagate end)
  end

  defp remove_empty_dead_queues(buffer, gmap, amap) do
	  ris = buffer
	  |> Stream.filter(fn {i, q} -> 
	  	not (q |> Enum.empty?
	  	and amap |> Map.get(i) == false) end)
	  |> Enum.map(fn {i, _} -> i end)
	  new_buffer = ris
	  |> Enum.zip(
	  	ris
	  	|> Enum.map(fn i -> Map.get(buffer, i) end))
	  |> Map.new
	  new_gmap = ris
	  |> Enum.zip(
	  	ris
	  	|> Enum.map(fn i -> Map.get(gmap, i) end))
	  |> Map.new
	  new_amap = ris
	  |> Enum.zip(
	  	ris
	  	|> Enum.map(fn i -> Map.get(amap, i) end))
	  |> Map.new
	  {new_buffer, new_gmap, new_amap}
	end

end