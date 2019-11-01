defmodule ReactiveMiddleware.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised
    children = [
      supervisor(ReactiveMiddleware.Registry, [[]]),
      supervisor(ReactiveMiddleware.Evaluator, [[]]),
      supervisor(ReactiveMiddleware.Connector, [[]]),
      supervisor(ReactiveMiddleware.Deployer, [[]])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Middleware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end