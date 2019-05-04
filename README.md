# BQuarp

		"A library for distributed reactive programming with flexible consistency guarantees drawing from Quarp.
    Features fifo, causality, glitch-freedom and logical-clock difference as guarantees.
   
    Generalizes and adapts Quarp to:
    * solve the issue of livelocking when enforcing guarantees with a time-component.
    * make possible consistency guarantees that require extra context state to be added as messages traverse the dependency graph, such as causality.
    * allow for the combination of signals with differing guarantees
    * allow for transitions between guarantees.
    * provide richer language primitives such as merge and filter.

    Can be easily extended with new guarantees if so desired by adding an implementation for the necessary operations in the Context and Guarantee module.

    Built on top of and integrated with Observables Extended, a Reactive Extensions library for Elixir.

    This library was developed mainly for academic purposes, 
    namely for exploring distributed reactive programming (for the IoT) with consistency guarantees."

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bquarp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bquarp, "~> 0.1.0"}
  ]
end
```