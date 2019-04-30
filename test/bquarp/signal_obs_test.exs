defmodule Test.BQuarp.SignalObsTest do
    use ExUnit.Case
    alias BQuarp.SignalObs, as: Sobs
    alias Observables.Obs
    alias Observables.Subject

    test "From observable" do
    testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.from_obs
    |> Obs.map(fn v -> send(testproc, v) end)

    	Subject.next(obs, :v)
    assert_receive({:v, []}, 1000, "did not get this message!")
    end

    test "To plain observable" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.to_plain_obs
    |> Obs.map(fn v -> send(testproc, v) end)

    	Subject.next(obs, {:v, :c})
    assert_receive(:v, 1000, "did not get this message!")
    end

    test "Add a context to a signal observable (1)" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.add_context({:g, 0})
    |> Obs.map(fn v -> send(testproc, v) end)

    Subject.next(obs, {:v, []})
    assert_receive({:v, [[{s, 0}]]}, 1000, "did not get this message!")
    Subject.next(obs, {:v, []})
    assert_receive({:v, [[{s, 1}]]}, 1000, "did not get this message!")
    end

    test "Remove a context from a signal observable" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.remove_context(2)
    |> Obs.map(fn v -> send(testproc, v) end)

    Subject.next(obs, {:v, [:c1, :c2, :c3, :c4]})
    assert_receive({:v, [:c1, :c2, :c4]}, 1000, "did not get this message!")
    end

    test "Keep a context of a signal observable" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.keep_context(2)
    |> Obs.map(fn v -> send(testproc, v) end)

    Subject.next(obs, {:v, [:c1, :c2, :c3, :c4]})
    assert_receive({:v, [:c3]}, 1000, "did not get this message!")
    end

    test "Set the context of a signal observable" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.set_context({:t, 0})
    |> Obs.map(fn v -> send(testproc, v) end)

    Subject.next(obs, {:v, [:c1, :c2, :c3, :c4]})
    assert_receive({:v, [0]}, 1000, "did not get this message!")
    Subject.next(obs, {:v, [:c1, :c2, :c3, :c4]})
    assert_receive({:v, [1]}, 1000, "did not get this message!")
    end

    test "Clear the context of a signal observable" do
    	testproc = self()

    obs = Subject.create()

    obs
    |> Sobs.clear_context
    |> Obs.map(fn v -> send(testproc, v) end)

    Subject.next(obs, {:v, [:c1, :c2, :c3, :c4]})
    assert_receive({:v, []}, 1000, "did not get this message!")
    end

    end