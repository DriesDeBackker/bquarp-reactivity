defmodule BQuarp.MixProject do
  use Mix.Project

  def project do
    [
      app: :bquarp,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/DriesDeBackker/bquarp-reactivity.git"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ReactiveMiddleware.Application, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:observables_extended, "~> 0.2.0"}
    ]
  end

  defp description() do
    "A library for distributed reactive programming with flexible consistency guarantees drawing from Quarp.
    Features fifo, causality, glitch-freedom and logical-clock difference as guarantees."
  end


  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "bquarp",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Dries De Backker"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/DriesDeBackker/bquarp-reactivity.git"}
    ]
end
end
