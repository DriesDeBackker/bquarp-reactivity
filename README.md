# BQUARP+: Buffered Quality Aware Reactive Programming with Flexible Consistency Guarantees (for the IoT)

A library for Distributed Reactive Programming (DRP) with flexible consistency guarantees. Draws from, implements and aims to improve upon 'Quality Aware Reactive Programming for the IoT (QUARP)' by Proença, Baquero (https://haslab.uminho.pt/joseproenca/files/quarp.pdf).

Provides a DSL features the familiar behaviours and event streams in the spirit of FRP as two signal abstractions. Allows for fifo (absence of guarantee), causal consistency, (single source) glitch-freedom and time-synchronization (i.e. clock difference restriction) as guarantees. See hexdocs for more information (https://hexdocs.pm/bquarp).

Specifically, BQUARP+ generalizes and adapts QUARP to:
* Enable FRP with Event Streams an Behaviours, complete with language primitives such as Merge and Filter for Event Streams and primitives enabling the reactivity associated with the interaction between Event Streams and Behaviours, such as Switch or Until.
* Prevent QUARP's proneness for live-locking when enforcing guarantees with a time aspect.
* Enable consistency guarantees that require extra context information to be added as messages traverse the dependency graph, such as causal consistency.
* Enable the lifting of multivariate primitive functions and their application to signals with differing guarantees.
* Allow for the lifting of multivariate primitive functions and their application to Behaviours. This models a CombineLatest in terms of discrete updates of (conceptually) continuous-time signals.
* Allow for the lifting of multivariate primitive functions and their application to Event Streams in addition to Behaviours. This models a Zip on time-series data in need of synchronized aggregation.
* Allow for the lifting of multivariate primitive functions and their application to both Behaviours and Event Streams at the same time. This models a CombineLatestSilent with the Behaviours silent and the Event Streams driving the propagation in a Zip-wise fashion while Behaviour state is kept.
* Enable transitions between guarantees to enforce different guarantees in different parts of the reactive application.

Can be easily deployed to embedded devices using https://nerves-project.org

Offers convenient deployment of small reactive programs to nodes in the network.

Can be extended with new guarantees - insofar as they can be realised using BQUARP+'s mechanisms - by adding a clause to all functions in the Context module, if so desired.

Built on top of and integrated with Observables Extended, a Reactive Extensions inspired library for Elixir (https://github.com/DriesDeBackker/observables-extended).

This library was developed mainly for academic purposes, namely for exploring distributed reactive programming (for the IoT) with consistency guarantees.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bquarp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bquarp, "~> 0.5.3"}
  ]
end
```