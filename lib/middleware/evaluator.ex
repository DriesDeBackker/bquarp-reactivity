defmodule ReactiveMiddleware.Evaluator do
  use GenServer
  require Logger
  alias GenServer

  ####################
  # CLIENT INTERFACE #
  ####################

  @doc """
  Start the GenServer.
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Evaluates a (remotely) sent program locally.
  """
  def evaluate(program) do
    GenServer.cast(__MODULE__, {:deploy_program, program})
  end

  ####################
  # SERVER CALLBACKS #
  ####################

  def init([]) do
    Logger.info("Starting the Evaluator")
    {:ok, %{}}
  end

  def handle_call({:evaluate, program}, _from, state) do
    res = program.()
    {:reply, :ok, state}
  end
end