alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.{Signal, EventStream, Behaviour}
alias Evaluation.Graph.GraphCreation
alias Evaluation.Graph
alias Evaluation.Commands.CommandsGeneration
alias Evaluation.Commands.CommandsInterpretation

guarantee = {:g, 0}

params = [
	hosts: [
		:"nerves@192.168.1.245", 
		:"nerves@192.168.1.143", 
		:"nerves@192.168.1.199", 
 		:"nerves@192.168.1.224", 
 		:"nerves@192.168.1.247"],
	nb_of_vars: 5,
	graph_depth: 4,
	signals_per_level_avg: 2,
	deps_per_signal_avg: 2,
	nodes_locality: 0.5,
	update_interval_mean: 2000,
	update_interval_sd: 100,
	experiment_length: 60_000]

Registry.set_guarantee(guarantee)

exp_handle = Subject.create
exp_handle
|> Behaviour.from_plain_obs
|> Signal.register(:exp)

var = fn name, im, isd ->
	fn -> 
		var_handle = Subject.create
		run = fn
			f -> 
				if Signal.signal(:exp) |> Behaviour.evaluate == true do
					Subject.next(var_handle, {name, round(:erlang.monotonic_time / 1000_000)})
				end
				:timer.sleep(round(:rand.normal(im, isd*isd)))
				f.(f)
			end
		Task.start fn -> run.(run) end
		var_handle
		|> Behaviour.from_plain_obs
		|> Signal.register(name)
	end
end

prop_ts1 = fn name, ts ->
	fn -> 
		Signal.signal(ts)
		|> Signal.liftapp(fn x -> x end)
		|> Signal.register(name)
		:ok
	end
end

prop_ts2 = fn name, ts1, ts2 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		Signal.liftapp([sts1, sts2], 
			fn x, y -> 
				Enum.max_by([x, y], fn {_xn, xt} -> xt end) 
			end)
		|> Signal.register(name)
		:ok
	end
end

prop_ts3 = fn name, ts1, ts2, ts3 ->
	fn ->
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		Signal.liftapp([sts1, sts2, sts3], 
			fn x, y, z -> 
				Enum.max_by([x, y, z], fn {_xn, xt} -> xt end) 
			end)
		|> Signal.register(name)
		:ok
	end
end

prop_ts4 = fn name, ts1, ts2, ts3, ts4 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		sts4 = Signal.signal(ts4)
		Signal.liftapp([sts1, sts2, sts3, sts4], 
			fn v, w, x, y -> 
				Enum.max_by([v, w, x, y], fn {_xn, xt} -> xt end)
			end)
		|> Signal.register(name)
		:ok
	end
end

final = fn var, fname ->
	fn -> 
		Signal.signal(fname)
		|> Behaviour.changes
		|> EventStream.filter(fn {xn, _xt} -> xn == var end)
		|> Signal.liftapp(fn {_xn, xt} -> [{xt, round(:erlang.monotonic_time / 1000_000)}] end)
		|> EventStream.scan(fn [tup], acc -> [tup | acc] end)
		|> EventStream.hold
		|> Signal.register(String.to_atom(Atom.to_string(var) <> "_" <> Atom.to_string(fname)))
		:ok
	end
end

g = GraphCreation.generateGraph(params)
CommandsGeneration.generateCommandsDelay(g, params)
|> CommandsInterpretation.interpretCommandsDelay({var, prop_ts1, prop_ts2, prop_ts3, prop_ts4, final})

Subject.next(exp_handle, true)