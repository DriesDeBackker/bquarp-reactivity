defmodule BQuarp.Registry do
  @doc """
  The Registry is responsible for keeping track of signals by their names.
  """
  use GenServer
  require Logger

  #############
  # GenServer #
  #############

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    table = :ets.new(:signals, [:named_table, :set, :protected])
    {:ok, %{:table => table, :subs => MapSet.new()}}
  end

  #############
  # Callbacks #
  #############

  def handle_cast(m, state) do
    Logger.debug "Cast: #{inspect m}"
    {:noreply, state}
  end


  def handle_call({:insert, signal, name}, _from, %{:table => t} = state) do
    :ets.insert(t, {name, signal})
    publish_new_signal(signal, name, state)
    {:reply, :ok, state}
  end

  def handle_call({:remove, name}, _from, %{:table => t} = state) do
    :ets.delete(t, name)
    {:reply, :ok, state}
  end

  def handle_call({:get, name}, _from, %{:table => t} = state) do
    case :ets.lookup(t, name) do
      [{^name, val}] -> {:reply, {:ok, val}, state}
      []             -> {:reply, {:error, "not found"}, state}
    end
  end

  def handle_call({:new_signal, signal, name}, _from, %{:table => t} = state) do
    :ets.insert(t, {name, signal})
    {:reply, :ok, state}
  end

  def handle_call({:subscribe, pid}, _from, %{:subs => ss} = state) do
    Logger.debug "Adding subscription for #{inspect pid}"
    {:reply, :ok, %{state | :subs => MapSet.put(ss, pid)}}
  end

  def handle_call({:unsubscribe, pid}, _from, %{:subs => ss} = state) do
    {:reply, :ok, %{state | :subs => MapSet.delete(ss, pid)}}
  end

  def handle_call(m, from, state) do
    Logger.debug "Call: #{inspect m} from #{inspect from}"
    {:reply, :ok, state}
  end

  def handle_info(m, state) do
    Logger.debug "Info: #{inspect m}"
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  defp publish_new_signal(signal, name, %{:subs => ss} = state) do
    ss
    |> Enum.map(fn(sub) -> GenServer.call(sub, {:new_signal, signal, name}) end)
  end

  #############
  # Interface #
  #############

  @doc """
  Adds a signal to the registry under the given name.
  """
  def add_signal(signal, name) do
    GenServer.call(__MODULE__, {:insert, signal, name})
  end

  @doc """
  Removes a signal from the registry under the given name.
  """
  def remove_signal(name) do
    GenServer.call(__MODULE__, {:remove, name})
  end

  @doc """
  Gets a signal by its name.
  """
  def get_signal(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @doc """
  Subscribe to events from the signal registry. When a new signal is added, this is sent to the subscribers.
  """
  def subscribe(pid) do
    GenServer.call(__MODULE__, {:subscribe, pid})
  end

  @doc """
  Unsubscribe a given pid from the registry events.
  """
  def unsubscribe(pid) do
    GenServer.call(__MODULE__, {:unsubscribe, pid})
  end

end
