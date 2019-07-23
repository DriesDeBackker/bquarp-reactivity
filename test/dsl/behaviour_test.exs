defmodule Test.BQuarp.BehaviourTest do
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

    s = B.from_plain_obs(obs, {:g, 0})
    assert(B.is_behaviour?(s))
    assert(Signal.carries_guarantee?(s, {:g, 0}))
    assert(B.evaluate(s) == nil)
    Subject.next(obs, :v)
    :timer.sleep(10)
    assert(B.evaluate(s) == :v)

    s
    |> Signal.to_plain_obs()
    |> Obs.map(fn x -> send(testprocess, x) end)

    Subject.next(obs, :v)
    assert_receive(:v, 1000, "did not get this message!")
  end

  # @tag :disabled
  test "to Event Stream (changes)" do
    obs = Subject.create()

    s1 = B.from_plain_obs(obs, {:g, 0})
    assert(B.is_behaviour?(s1))
    assert(Signal.carries_guarantee?(s1, {:g, 0}))

    s2 = B.changes(s1)
    assert(ES.is_event_stream?(s2))
  end

  # @tag :disabled
  test "switch" do
    s1 = Subject.create()
    s2 = Subject.create()
    s3 = Subject.create()
    hs = Subject.create()

    b1 = B.from_plain_obs(s1, nil)
    b2 = B.from_plain_obs(s2, nil)
    b3 = B.from_plain_obs(s3, nil)
    hes = ES.from_plain_obs(hs, nil)

    br = B.switch(b1, hes)

    Subject.next(s2, :s2a)
    :timer.sleep(10)
    assert(B.evaluate(br) == nil)

    Subject.next(s3, :s3a)
    :timer.sleep(10)
    assert(B.evaluate(br) == nil)

    Subject.next(s1, :s1a)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s1a)

    Subject.next(s3, :s3b)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s1a)

    Subject.next(s1, :s1b)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s1b)

    assert(B.evaluate(b2) == :s2a)
    Logger.debug("Switch to behaviour 2")
    Subject.next(hs, b2)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2a)

    Subject.next(s1, :s1c)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2a)

    Subject.next(s2, :s2b)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2b)

    Subject.next(s3, :s3c)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2b)

    assert(B.evaluate(b3) == :s3c)
    Logger.debug("Switch to behaviour 3")
    Subject.next(hs, b3)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s3c)

    Subject.next(s3, :s3d)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s3d)

    Subject.next(s1, :s1d)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s3d)

    Subject.next(s2, :s2c)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s3d)
  end

  # @tag :disabled
  test "until" do
    s1 = Subject.create()
    s2 = Subject.create()
    s3 = Subject.create()

    b1 = B.from_plain_obs(s1, nil)
    b2 = B.from_plain_obs(s2, nil)
    es = ES.from_plain_obs(s3, nil)

    br = 
      b1
      |> B.until(b2, es)

    Subject.next(s2, :s2a)
    :timer.sleep(10)
    assert(B.evaluate(br) == nil)

    Subject.next(s1, :s1a)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s1a)

    assert(B.evaluate(b2) == :s2a)
    Logger.debug("Switching to behaviour 2")
    Subject.next(s3, :whatever)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2a)

    Subject.next(s1, :s1b)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2a)

    Subject.next(s2, :s2b)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2b)

    Subject.next(s3, :irrelevant)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2b)

    Subject.next(s1, :s1c)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2b)

    Subject.next(s2, :s2c)
    :timer.sleep(10)
    assert(B.evaluate(br) == :s2c)
  end
end
