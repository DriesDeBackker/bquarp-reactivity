defmodule Test.BQuarp.SignalTest do
  use ExUnit.Case
  alias Reactivity.DSL.Signal
  alias Reactivity.DSL.Behaviour, as: B
  alias Reactivity.DSL.EventStream, as: ES
  alias Observables.Obs
  alias Observables.Subject

  require Logger

  # @tag :disabled
  test "add, remove, set and keep guarantees" do
    obs = Subject.create()

    signal =
      obs
      |> Behaviour.from_plain_obs({:g, 0})
      |> Signal.add_guarantee({:t, 0})

    assert(Signal.guarantees(signal) |> Enum.count() == 2)
    assert(Signal.carries_guarantee?(signal, {:g, 0}))
    assert(Signal.carries_guarantee?(signal, {:t, 0}))

    signal =
      signal
      |> Signal.remove_guarantee({:g, 0})

    assert(not Signal.carries_guarantee?(signal, {:g, 0}))
    assert(Signal.guarantees(signal) |> Enum.count() == 1)

    signal =
      signal
      |> Signal.set_guarantee({:c, 0})

    assert(Signal.carries_guarantee?(signal, {:c, 0}))
    assert(not Signal.carries_guarantee?(signal, {:t, 0}))
    assert(Signal.guarantees(signal) |> Enum.count() == 1)

    signal =
      signal
      |> Signal.add_guarantee({:g, 0})
      |> Signal.add_guarantee({:t, 0})
      |> Signal.keep_guarantee({:t, 0})

    assert(Signal.carries_guarantee?(signal, {:t, 0}))
    assert(not Signal.carries_guarantee?(signal, {:g, 0}))
    assert(not Signal.carries_guarantee?(signal, {:c, 0}))
  end

  # @tag :disabled
  test "lift and apply a function to a Signal (1)" do
    testproc = self()
    obs = Subject.create()

    obs
    |> B.from_plain_obs()
    |> Signal.liftapp(fn x -> x * 2 end)
    |> B.changes
    |> ES.each(fn x -> send(testproc, x) end)

    Subject.next(obs, 1)
    assert_receive(2, 1000, "did not get this message!")

    Subject.next(obs, 5)
    assert_receive(10, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "lift and apply a function to a Signal (1)" do
    testproc = self()
    obs = Subject.create()

    br = 
      obs
      |> B.from_plain_obs()
      |> Signal.liftapp(fn x -> x * 2 end)
    assert(B.is_behaviour?(br))
    er = B.changes(br)
    assert(ES.is_event_stream?(er))
    ES.each(er, fn x -> send(testproc, x) end)
    

    Subject.next(obs, 1)
    assert_receive(2, 1000, "did not get this message!")

    Subject.next(obs, 5)
    assert_receive(10, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "lift and apply a function to two signals (1)" do
    testproc = self()
    obs1 = Subject.create()
    obs2 = Subject.create()

    s1 =
      obs1
      |> ES.from_plain_obs({:t, 0})
    assert(ES.is_event_stream?(es1))

    s2 =
      obs2
      |> ES.from_plain_obs({:t, 0})
    assert(ES.is_event_stream?(es2))

    sr = 
      [s1, s2]
      |> Signal.liftapp(fn x, y -> x + y end)
    assert(ES.is_event_stream?(sr))
    ES.each(sr, fn x -> send(testproc, x) end)

    Subject.next(obs1, 1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs2, 3)
    assert_receive(4, 1000, "did not get this message!")

    Subject.next(obs2, 5)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs1, 5)
    assert_receive(10, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "lift and apply a function to two signals (2)" do
    testproc = self()
    obs1 = Subject.create()
    obs2 = Subject.create()

    s1 =
      obs1
      |> B.from_plain_obs(nil)
    assert(B.is_behaviour?(s1))

    s2 =
      obs2
      |> B.from_plain_obs(nil)
    assert(B.is_behaviour?(s2))

    sr =
      [s1, s2]
      |> Signal.liftapp(fn x, y -> x + y end)
    assert(B.is_behaviour?(sr))
    er = B.changes(sr)
    assert(ES.is_event_stream?(er))
    ES.each(er, fn x -> send(testproc, x) end)

    Subject.next(obs1, 1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs2, 3)
    assert_receive(4, 1000, "did not get this message!")

    Subject.next(obs1, 3)
    assert_receive(6, 1000, "did not get this message!")
  end

  test "lift and apply a function to two signals (3)" do
    testproc = self()
    obs1 = Subject.create()
    obs2 = Subject.create()

    s1 =
      obs1
      |> B.from_plain_obs(nil)

    s2 =
      obs2
      |> ES.from_plain_obs(nil)

    sr = 
      [s1, s2]
      |> Signal.liftapp(fn x, y -> x + y end)
    assert(ES.is_event_stream?(sr)
    ES.each(sr, fn x -> send(testproc, x) end)

    Subject.next(obs2, 1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs2, 5)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs1, 3)
    assert_receive(4, 1000, "did not get this message!")
    assert_receive(8, 1000, "did not get this message!")
  end

  test "lift and apply a list function to a variable number of signals" do
    testproc = self()

    obs1 = Subject.create()
    obs2 = Subject.create()
    obs3 = Subject.create()
    hobs = Subject.create()

    s1 = B.from_plain_obs(obs1, nil)
    s2 = B.from_plain_obs(obs2, nil)
    s3 = B.from_plain_obs(obs3, nil)
    hes = ES.from_plain_obs(hobs, nil)

    sr = 
      [s1, s2]
      |> Signal.liftapp_var(hes, fn xs -> Enum.sum(xs) / length(xs) end)
    assert(B.is_behaviour?(sr))
    er = B.changes(sr)
    assert(ES.is_event_stream?(er))
    ES.each(er, fn x -> send(testproc, x) end)

    Subject.next(obs1, 1)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs2, 5)
    assert_receive(3.0, 1000, "did not get this message!")

    Subject.next(obs1, 3)
    assert_receive(4.0, 1000, "did not get this message!")

    Subject.next(hobs, signal3)

    Subject.next(obs1, 7)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end

    Subject.next(obs1, 4)

    receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
  end
end
