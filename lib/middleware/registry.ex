defmodule ReactiveMiddleware.Registry do
  @doc """
  The Registry is responsible for 
  * keeping track of signals by their names,
  * holding the consistency guarantee that is in use, and
  * synchronizing signals and guarantee with other registries
    in order to create a globally consistent view of both.
  """
  use GenServer
  require Logger

  ####################
  # CLIENT INTERFACE #
  ####################

  @doc """
  Start the registry
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Adds a signal to the registry under the given name.
  """
  def add_signal(signal, name) do
    GenServer.call(__MODULE__, {:insert, signal, name})
  end

  @doc """
  Removes the signal with the given name if it exists and is locally hosted.
  """
  def remove_signal(name) do
    GenServer.call(__MODULE__, {:remove, name})
  end

  @doc """
  Removes all signals hosted at the given host from the registry.
  """
  def remove_signals_of(host) do
    GenServer.call(__MODULE__, {:remove_all, host})
  end

  @doc """
  Gets a signal by its name.
  """
  def get_signal(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  @doc """
  Gets the names of all available signals.
  """
  def get_signals() do
    GenServer.call(__MODULE__, {:get_all})
  end

  @doc """
  Gets the node where the signal with the given name is hosted.
  """
  def get_signal_host(name) do
    GenServer.call(__MODULE__, {:get_signal_host, name})
  end

  @doc """
  Gets the consistency guarantee that is in use
  """
  def get_guarantee() do
    GenServer.call(__MODULE__, {:get_guarantee})
  end

  @doc """
  Sets the consistency guarantee to use.
  """
  def set_guarantee(guarantee) do
    GenServer.call(__MODULE__, {:set_guarantee, guarantee})
  end

  @doc """
  Synchronize with all connected nodes.
  """
  def update() do
    GenServer.cast(__MODULE__, {:update})
  end

  @doc """
  Synchronize with the given node.
  """
  def synchronize(node_name) do
    GenServer.cast(__MODULE__, {:synchronize, node_name})
  end

  ####################
  # SERVER CALLBACKS #
  ####################

  def init(_args) do
    Logger.info("Starting the Registry")
    stable = :ets.new(:signals, [:named_table, :set, :protected])
    htable = :ets.new(:signal_names, [:named_table, :set, :protected])
    update()
    {:ok, %{stable: stable, htable: htable, guarantee: nil}}
  end

  def handle_call({:insert, signal, name}, _from, state) do
    host = Node.self
    add_signal(signal, name, host, state)
    publish_new_signal(name, signal, state)
    {:reply, :ok, state}
  end

  def handle_call({:remove, name}, _from, state) do
    host = Node.self
    case get_signal_host_from_name(name, state) do
      ^host -> 
        remove_signal(name, host, state)
        publish_signal_removed(name, state)
        {:reply, :ok, state}
      nil -> {:reply, {:error, "not found"}, state}
      _remote -> {:reply, {:error, "Cannot remove remote signal locally."}, state}
    end
  end

  def handle_call({:remove_all, host}, _from, %{stable: st, htable: ht} = state) do
    get_names_from_host(host, state)
    |> Enum.map(fn name -> :ets.delete(st, name) end)
    :ets.delete(ht, host)
    {:reply, :ok, state}
  end

  def handle_call({:get, name}, _from, state) do
    case get_signal_from_name(name, state) do
      nil -> {:reply, {:error, "not found"}, state}
      sig -> {:reply, {:ok, sig}, state}
    end
  end

  def handle_call({:get_all}, _from, %{stable: st} = state) do
    signal_tuples = :ets.tab2list(st)
    {:reply, {:ok, signal_tuples}, state}
  end

  def handle_call({:get_signal_host, name}, _from, state) do
    case get_signal_host_from_name(name, state) do
      nil -> {:reply, {:error, "not found"}, state}
      host -> {:reply, {:ok, host}, state}
    end
  end

  def handle_call({:get_guarantee}, _from, %{guarantee: guarantee} = state) do
    {:reply, guarantee, state}
  end

  def handle_call({:set_guarantee, guarantee}, _from, state) do
    new_state = %{state | guarantee: guarantee}
    publish_new_guarantee(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call(m, from, state) do
    Logger.debug("Call: #{inspect(m)} from #{inspect(from)}.")
    {:reply, :ok, state}
  end

  def handle_cast({:new_signal, signal, name, host}, state) do
    Logger.info("New signal #{inspect name} available at host: #{inspect host}.")
    add_signal(signal, name, host, state)
    {:noreply, state}
  end

  def handle_cast({:signal_removed, name, host}, state) do
    Logger.info("Signal #{inspect name} removed from host: #{inspect host}.")
    remove_signal(name, host, state)
    {:noreply, state}
  end

  def handle_cast({:new_guarantee, guarantee}, state) do
    Logger.info("Guarantee set to #{inspect guarantee}.")
    new_state = %{state | guarantee: guarantee}
    {:noreply, new_state}
  end

  def handle_cast({:update}, state) do
    Node.list
    |> Enum.map(fn n -> synchronize(n) end)
    {:noreply, state}
  end

  def handle_cast({:synchronize, node_name}, state) do
    GenServer.cast(__MODULE__, {:send_signals, node_name})
    rem_reg = :global.whereis_name({node_name, :registry})
    GenServer.cast(rem_reg, {:send_signals, Node.self})
    {:noreply, state}
  end

  def handle_cast({:send_signals, node_name}, state) do
    Logger.debug("Synchronizing with registry of node #{inspect(node_name)}.")
    rem_reg = :global.whereis_name({node_name, :registry})
    Logger.debug("The registry of the new node: #{inspect rem_reg}.")
    # send a copy of all locally registered signals to the registry of the new node
    signals = 
      get_names_from_host(Node.self, state)
      |> Enum.map(fn name -> {name, get_signal_from_name(name, state)} end)
    GenServer.cast(rem_reg, {:update_signals, signals, Node.self})
    {:noreply, state}
  end

  def handle_cast({:update_signals, signals_by_name, host}, %{stable: st, htable: ht} = state) do
    names = 
      signals_by_name
      |> Enum.map(fn {name, _signal} -> name end)
    to_be_removed = get_names_from_host(host, state) -- names
    :ets.insert(ht, {host, names})
    signals_by_name
    |> Enum.map(fn {name, signal} -> :ets.insert(st, {name, {host, signal}}) end)
    to_be_removed
    |> Enum.map(fn name -> :ets.delete(st, name) end)
    {:noreply, state}
  end

  def handle_cast(m, state) do
    Logger.debug("Cast: #{inspect(m)}")
    {:noreply, state}
  end

  def handle_info(m, state) do
    Logger.debug("Info: #{inspect(m)}.")
    {:noreply, state}
  end

  ############################
  # IMPLEMENTATION / HELPERS #
  ############################

  defp publish_new_signal(name, signal, %{}) do
    Node.list
    |> Enum.map(fn n -> :global.whereis_name({n, :registry}) end)
    |> Enum.map(fn r -> GenServer.cast(r, {:new_signal, signal, name, Node.self}) end)
  end

  defp publish_signal_removed(name, %{}) do
    Node.list
    |> Enum.map(fn n -> :global.whereis_name({n, :registry}) end)
    |> Enum.map(fn r -> GenServer.cast(r, {:signal_removed, name, Node.self}) end)
  end

  defp publish_new_guarantee(%{guarantee: guarantee}) do
    Node.list
    |> Enum.map(fn n -> :global.whereis_name({n, :registry}) end)
    |> Enum.map(fn r -> GenServer.cast(r, {:new_guarantee, guarantee}) end)
  end

  defp add_signal(signal, name, host, %{stable: st, htable: ht} = state) do
    :ets.insert(st, {name, {host, signal}})
    :ets.insert(ht, {host, [name | get_names_from_host(host, state)]})
  end

  defp remove_signal(name, host, %{stable: st, htable: ht} = state) do
    :ets.delete(st, name)
    :ets.insert(ht, {host, get_names_from_host(host, state) -- [name]})
  end

  defp get_names_from_host(host, %{htable: ht}) do
    case :ets.lookup(ht, host) do
      [{^host, names}] -> names
      [] -> []
    end
  end

  defp get_signal_from_name(name, %{stable: st}) do
    case :ets.lookup(st, name) do
      [{^name, {_host, signal}}] -> signal
      [] -> nil
    end
  end

  defp get_signal_host_from_name(name, %{stable: st}) do
    case :ets.lookup(st, name) do
      [{^name, {host, _signal}}] -> host
      [] -> nil
    end
  end
end