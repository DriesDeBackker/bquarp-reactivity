# BQuarp

		"A library for distributed reactive programming with flexible consistency guarantees drawing from Quarp.
    Features fifo, causality, glitch-freedom and logical-clock difference as guarantees.
    Solves the issue of livelocking in Quarp when enforcing guarantees with a time-component.
    Allows the combination of signals with differing guarantees and transitions between guarantees.
    Can be easily extended with new guarantees if so desired.
    Built on top of and integrated with Observables Extended, a Reactive Extensions library for Elixir.
    This library was developed mainly for academic purposes, namely for exploring distributed reactive programming (for the IoT) with consistency guarantees."

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bquarp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bquarp, "~> 0.2.0"}
  ]
end
```