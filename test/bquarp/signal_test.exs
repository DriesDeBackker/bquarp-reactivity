defmodule Test.BQuarp.SignalTest do
	use ExUnit.Case
	alias BQuarp.Signal
	alias Observables.Obs
	alias Observables.Subject

	require Logger

	#@tag :disabled
	test "to and from observable" do
		testprocess = self()

		obs = Subject.create

		signal = obs
		|> Signal.from_obs({:g, 0})
		assert(Signal.carries_guarantee?(signal, {:g, 0}))

		signal
		|> Signal.to_obs
		|> Obs.map(fn x -> send(testprocess, x) end)
		
		Subject.next(obs, :v)
		assert_receive(:v, 1000, "did not get this message!")
	end

	#@tag :disabled
	test "add, remove, set and keep guarantees" do
		obs = Subject.create
		signal = obs
		|> Signal.from_obs({:g, 0})
		|> Signal.add_guarantee({:t, 0})
		assert(Signal.guarantees(signal) |> Enum.count == 2)
		assert(Signal.carries_guarantee?(signal, {:g, 0}))
		assert(Signal.carries_guarantee?(signal, {:t, 0}))

		signal = signal
		|> Signal.remove_guarantee({:g, 0})
		assert(not Signal.carries_guarantee?(signal, {:g, 0}))
		assert(Signal.guarantees(signal) |> Enum.count == 1)

		signal = signal
		|> Signal.set_guarantee({:c, 0})
		assert(Signal.carries_guarantee?(signal, {:c, 0}))
		assert(not Signal.carries_guarantee?(signal, {:t, 0}))
		assert(Signal.guarantees(signal) |> Enum.count == 1)

		signal = signal
		|> Signal.add_guarantee({:g, 0})
		|> Signal.add_guarantee({:t, 0})
		|> Signal.keep_guarantee({:t, 0})
		assert(Signal.carries_guarantee?(signal, {:t, 0}))
		assert(not Signal.carries_guarantee?(signal, {:g, 0}))
		assert(not Signal.carries_guarantee?(signal, {:c, 0}))
	end

	#@tag :disabled
	test "filter" do
		testprocess = self()

		obs = Subject.create
		signal = obs
		|> Signal.from_obs({:g, 0})
		|> Signal.filter(fn x -> x > 5 end)
		signal
		|> Signal.to_obs
		|> Obs.map(fn x -> send(testprocess, x) end)

		Subject.next(obs, 10)
		assert_receive(10, 1000, "did not get this message!")

		Subject.next(obs, 4)
		receive do
      x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
    after
      0 -> :ok
    end
	end

	#@tag :disabled
	test "merge" do
		testprocess = self()

		obs1 = Subject.create
		obs2 = Subject.create
		signal1 = obs1
		|> Signal.from_obs({:t, 0})
		signal2 = obs2
		|> Signal.from_obs({:t, 0})
		[signal1, signal2]
		|> Signal.merge
		|> Signal.to_obs
		|> Obs.map(fn x -> send(testprocess, x) end)

		Subject.next(obs1, :v1)
		assert_receive(:v1, 1000, "did not get this message!")

		Subject.next(obs2, :v2)
		assert_receive(:v2, 1000, "did not get this message!")
	end

	#@tag :disabled
  test "scan" do
    testproc = self()

    start = 1
    tend = 50

    # Create a range, turn into signal and scan.
    Obs.range(start, tend, 100)
    |> Signal.from_obs
    |> Signal.scan(fn x, y -> x + y end)
    |> Signal.to_obs
    |> Obs.each(fn v -> send(testproc, v) end)

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

  #@tag :disabled
  test "lift and apply a function to a signal" do
  	testproc = self()
    obs = Subject.create

    obs
    |> Signal.from_obs
    |> Signal.liftapp(fn x -> x * 2 end)
    |> Signal.each(fn x -> send(testproc, x) end)

    Subject.next(obs, 1)
    assert_receive(2, 1000, "did not get this message!")

    Subject.next(obs, 5)
    assert_receive(10, 1000, "did not get this message!")
  end

  #@tag :disabled
  test "lift and apply a function to two signals (1)" do
  	testproc = self()
    obs1 = Subject.create
    obs2 = Subject.create

    signal1 = obs1
    |> Signal.from_obs({:t, 0})
    signal2 = obs2
    |> Signal.from_obs({:t, 0})
    [signal1, signal2]
    |> Signal.liftapp(fn x, y -> x + y end)
    |> Signal.each(fn x -> send(testproc, x) end)

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

  #@tag :disabled
  test "lift and apply a function to two signals (2)" do
  	testproc = self()
    obs1 = Subject.create
    obs2 = Subject.create

    signal1 = obs1
    |> Signal.from_obs({:fu, 0})
    signal2 = obs2
    |> Signal.from_obs({:fu, 0})
    [signal1, signal2]
    |> Signal.liftapp(fn x, y -> x + y end)
    |> Signal.each(fn x -> send(testproc, x) end)

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
    obs1 = Subject.create
    obs2 = Subject.create

    signal1 = obs1
    |> Signal.from_obs({:fu, 0})
    signal2 = obs2
    |> Signal.from_obs({:fp, 0})
    [signal1, signal2]
    |> Signal.liftapp(fn x, y -> x + y end)
    |> Signal.each(fn x -> send(testproc, x) end)

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

  test "lift and apply a function to two signals (4)" do
    testproc = self()
    obs1 = Subject.create
    obs2 = Subject.create

    signal1 = obs1
    |> Signal.from_obs({:fu, 0})
    signal2 = obs2
    |> Signal.from_obs({:fu, 0})
    [signal1, signal2]
    |> Signal.liftapp(fn x, y -> x + y end)
    |> Signal.each(fn x -> send(testproc, x) end)

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
    assert_receive(8, 1000, "did not get this message!")
  end

  test "lift and apply a list function to a variable number of signals" do
    testproc = self()
    obs1 = Subject.create
    obs2 = Subject.create
    obs3 = Subject.create
    hobs = Subject.create

    signal1 = obs1
    |> Signal.from_obs({:fu, 0})
    signal2 = obs2
    |> Signal.from_obs({:fu, 0})
    signal3 = obs3
    |> Signal.from_obs({:fu, 0})
    hsignal = hobs
    |> Signal.from_obs
    [signal1, signal2]
    |> Signal.liftapp_var(hsignal, fn xs -> Enum.sum(xs) / length(xs) end)
    |> Signal.each(fn x -> send(testproc, x) end)

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

    Subject.next(obs3, 3)
    receive do
      x -> IO.puts("FFFFFFFFFFFFFFFFFFFuck: #{inspect x}")
    end
  end

end