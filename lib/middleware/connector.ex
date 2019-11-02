defmodule ReactiveMiddleware.Connector do
	use GenServer
	alias ReactiveMiddleware.Registry
	alias ReactiveMiddleware.Evaluator
	require Logger

	@port 6666
	@multicast {224, 0, 0, 225}
	@cookie :hottentottententententoonstelling

	####################
	# CLIENT INTERFACE #
	####################

	# Start the server. Called by the app.
	def start_link(_arg) do
  		GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	# Connect manually with a given set of nodes 
	# (when udp multicast is disfunctional on your machine).
	def manual_connect_and_subscribe(ns) do
		GenServer.call(__MODULE__, {:connect_all, ns})
	end

	####################
	# SERVER CALLBACKS #
	####################

	def init([]) do
		GenServer.cast(__MODULE__, {:initialize})
		{:ok, nil}
	end

	# Handles the initial request for initialization
	# Loops until this node has a fully qualified name (as a result of being networked)
	# Then calls the initialize helper function to handle the details.
	def handle_cast({:initialize}, nil) do
		if Node.self == :nonode@nohost do
			#Logger.warn("FQN not materialized yet!")
			:timer.sleep(500)
			#Logger.warn("Trying again!")
			GenServer.cast(__MODULE__, {:initialize})
			{:noreply, nil}
		else
			Node.set_cookie(@cookie)
			:rand.seed(:exsplus, :erlang.now)
			:timer.sleep(:rand.uniform(1000))
			{:ok, s} = initialize()
			{:noreply, s}
		end
	end

	@doc """
	This message is received as a result of the Connector messaging itself for the purpose
	of periodically announcing our presence in the face of no connections
	(e.g. as a result of a temporary network disruption).
	"""
	def handle_cast({:monitor}, s) do
		monitor()
		{:noreply, s}
	end

	# Handles an incoming announcement that is broadcasted by a new node.
	def handle_info({:udp, _clientSocket, _clientIp, _clientPort, msg}, s) do
	  	name = String.to_atom(msg)
	  	if name != Node.self do
	  		Logger.info("New node has announced itself: #{name}")
	  		handle_discovery(name)
	  	end
	  	{:noreply, s}
	end

	@doc """
	This message is receives when a node returns. (Result of monitoring nodes).
	"""
	def handle_info({:nodeup, remote}, s) do
		Logger.info("(Re)connected to remote node: #{inspect remote}.")
		handle_connect(remote)
		{:noreply, s}
	end

	@doc """
	This message is received when a node disappears from the network.
	"""
	def handle_info({:nodedown, remote}, s) do
		handle_disconnect(remote)
		{:noreply, s}
	end

	@doc """
	This message is received when a manual connect to a list of nodes is performed.
	"""
	def handle_call({:connect_all, ns}, _from, s) do
		ns
		|> Enum.each(fn n -> handle_connect(n) end)
		{:reply, :ok, s}
	end


	############################
	# IMPLEMENTATION / HELPERS #
	############################

	# Initializes this nodes network connections automatically.
	# - Registers the Registry and Evaluator globally
	# - Calls the announce function
	# Actually a helper function but can be called manually as well.
	defp initialize() do
		Logger.info("Starting the Connector")
	    register()
	    # Detect node disconnects and reconnects.
	    :net_kernel.set_net_ticktime(5, 0)
    	:net_kernel.monitor_nodes(true)
	    {:ok, s} = open_multicast(@port, @multicast)
	    announce()
	    monitor()
	    {:ok, s}
	end

	# Opens a multicast socket that listens to incoming announcements of new nodes.
	defp open_multicast(port, addr) do
		Logger.debug("Opening a multicast socket")
		:gen_udp.open(port, [
			:binary,
			#Put the following line in comments on a Windows machine.
			#{:ip, addr},
			{:reuseaddr, true},
			{:multicast_ttl, 4},
    	{:multicast_loop, true},
    	{:broadcast, true},
    	{:add_membership, {addr, {0, 0, 0, 0}}},
    	{:active, true}
		])
	end

	# Registers the Registry and Evaluator globally
	defp register() do
		Logger.info("Registering the registry and evaluator globally under #{Node.self}")
	    :global.register_name({Node.self, :registry}, Process.whereis(Registry))
	    :global.register_name({Node.self, :evaluator}, Process.whereis(Evaluator))
	end

	# Announces our presence on the network by broadcasting this node's name.
	defp announce() do
	  	Logger.info("Announcing our presence on the network")
	  	case :gen_udp.open(0, mode: :binary) do
		  	{:ok, sender} -> :gen_udp.send(sender, @multicast, @port, "#{Node.self()}")
		  	{:error, _err} -> raise "Could not open send socket"
		  end
	end

	defp handle_disconnect(remote) do
    Logger.info("Lost: #{inspect remote}")
    Logger.info("Removing its signals from the registry")
    Registry.remove_signals_of(remote)
	end

	defp handle_discovery(remote) do
		Logger.info("Connecting with: #{inspect remote}")
		Node.connect(remote)
	end

	defp handle_connect(remote) do
		:global.sync()
		Logger.info("Synchronizing with: #{inspect remote}")
		Registry.synchronize(remote)
	end

	defp monitor() do
		if Node.list == [] do
			announce()
		end
		Task.start(fn ->
			:timer.sleep(2000)
			GenServer.cast(__MODULE__, {:monitor})
		end)
	end
end