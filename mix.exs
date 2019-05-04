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
      {:observables_extended, "~> 0.1.0"}
    ]
  end

  defp description() do
    "A library for distributed reactive programming with flexible consistency guarantees drawing from Quarp.
    Features fifo, causality, glitch-freedom and logical-clock difference as guarantees.
   
    Generalizes and adapts Quarp to 
    * solve the issue of livelocking when enforcing guarantees with a time-component.
    * make possible consistency guarantees that require extra context state to be added as messages
      traverse the dependency graph, such as causality.
    * allow for the combination of signals with differing guarantees
    * allow for transitions between guarantees.
    * provide richer language primitives such as merge and filter.

    Can be easily extended with new guarantees if so desired
    by adding an implementation for the necessary operations in the Context and Guarantee module.

    Built on top of and integrated with Observables Extended, a Reactive Extensions library for Elixir.

    This library was developed mainly for academic purposes, 
    namely for exploring distributed reactive programming (for the IoT) with consistency guarantees."
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
