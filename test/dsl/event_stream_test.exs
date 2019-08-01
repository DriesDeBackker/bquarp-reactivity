defmodule Test.BQuarp.EventStreamTest do
  use ExUnit.Case
  alias Reactivity.DSL.Signal
  alias Reactivity.DSL.Behaviour, as: B
  alias Reactivity.DSL.EventStream, as: ES
  alias Observables.Obs
  alias Observables.Subject

  require Logger

  # @tag :disabled
  test "to and from Observable" do
    testprocess = self()

    obs = Subject.create()

    s = ES.from_plain_obs(obs, {:t, 0})
    assert(ES.is_event_stream?(s))
    assert(Signal.carries_guarantee?(s, {:t, 0}))

    s
    |> Signal.to_plain_obs()
    |> Obs.map(fn x -> send(testprocess, x) end)

    Subject.next(obs, :v)
    assert_receive(:v, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "to Behaviour" do
    obs = Subject.create()

    s1 = ES.from_plain_obs(obs, {:t, 0})
    assert(ES.is_event_stream?(s1))
    assert(Signal.carries_guarantee?(s1, {:t, 0}))

    s2 = ES.hold(s1)
    assert(B.is_behaviour?(s2))
  end

  # @tag :disabled
  test "filter" do
    testprocess = self()

    obs = Subject.create()

    obs
    |> ES.from_plain_obs({:g, 0})
    |> ES.filter(fn x -> x > 5 end)
    |> ES.each(fn x -> send(testprocess, x) end)

    Subject.next(obs, 10)
    assert_receive(10, 1000, "did not get this message!")

    Subject.next(obs, 4)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end

  # @tag :disabled
  test "merge" do
    testprocess = self()

    obs1 = Subject.create()
    obs2 = Subject.create()

    s1 =
      obs1
      |> ES.from_plain_obs({:t, 0})

    s2 =
      obs2
      |> ES.from_plain_obs({:t, 0})

    [s1, s2]
    |> ES.merge()
    |> Signal.to_plain_obs()
    |> Obs.map(fn x -> send(testprocess, x) end)

    Subject.next(obs1, :v1)
    assert_receive(:v1, 1000, "did not get this message!")

    Subject.next(obs2, :v2)
    assert_receive(:v2, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "rotate" do
    testprocess = self()

    a = Subject.create()
    b = Subject.create()
    c = Subject.create()

    s1 = ES.from_plain_obs(a, {:t, 0})
    s2 = ES.from_plain_obs(b, {:t, 0})
    s3 = ES.from_plain_obs(c, {:t, 0})

    [s1, s2, s3]
    |> ES.rotate()
    |> ES.each(fn x -> send(testprocess, x) end)

    Subject.next(b, :b1)
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(c, :c1)
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(b, :b2)
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(a, :a1)
    assert_receive(:a1, 1000, "did not get this message!")
    assert_receive(:b1, 1000, "did not get this message!")
    assert_receive(:c1, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(a, :a2)
    assert_receive(:a2, 1000, "did not get this message!")
    assert_receive(:b2, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(c, :c2)
    assert_receive(:c2, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(b, :b3)
    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(a, :a3)
    assert_receive(:a3, 1000, "did not get this message!")
    assert_receive(:b3, 1000, "did not get this message!")

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      200 -> :ok
    end
  end

  # @tag :disabled
  test "scan" do
    testproc = self()

    start = 1
    tend = 50

    # Create a range, turn into signal and scan.
    Obs.range(start, tend, 100)
    |> ES.from_plain_obs()
    |> ES.scan(fn x, y -> x + y end)
    |> ES.each(fn v -> send(testproc, v) end)

    # Receive all the values.
    Enum.scan(1..50, fn x, y -> x + y end)
    |> Enum.map(fn v ->
      receive do
        ^v -> :ok
      after
        10000 ->
          assert "Did not receive item in time: #{inspect(v)}" == ""
      end
    end)

    # Receive no other values.
    receive do
      x ->
        assert "received another value: #{inspect(x, charlists: :as_lists)} " == ""
    after
      1000 ->
        :ok
    end
  end

end
