defmodule BQuarp.MixProject do
  use Mix.Project

  def project do
    [
      app: :bquarp,
      version: "0.5.2",
      elixir: "~> 1.8",
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
      #mod: {ReactiveMiddleware.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rp_middleware, "~> 0.1.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:observables_extended, "~> 0.3.4"},
    ]
  end

  defp description() do
    "A library for distributed reactive programming with flexible consistency guarantees drawing from QUARP and Rx..
    Features the familiar behaviours and event streams in the spirit of FRP."
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
