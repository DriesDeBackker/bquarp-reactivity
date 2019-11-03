alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.{Signal, EventStream, Behaviour}
alias Evaluation.Graph.GraphCreation
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
	experiment_length: 600_000]
]


Registry.set_guarantee(guarantee)

var = fn name, im, isd ->
	var_handle = Subject.create
	run = fn
		f -> 
			Subject.next(var_handle, {name, :erlang.monotonic_time})
			:timer.sleep(:rand.normal(im, isd*isd))
			f.(f)
		end
	:timer.sleep(5000)
	Task.start fn -> run.(run) end
	var_handle
	|> Behaviour.from_plain_obs
	|> Signal.register(name)
end

prop_ts1 = fn name, ts ->
	sts = Signal.signal(ts)
	p = Signal.liftapp(sts, fn x -> x end)
	|> Signal.register(name)
	:ok
end

prop_ts2 = fn name, ts1 ->
	sts1 = Signal.signal(ts1)
	sts2 = Signal.signal(ts2)
	p = Signal.liftapp([sts1, sts2], 
		fn x, y -> 
			Enum.max_by([x, y], fn {xn, xt} -> xt end) 
		end)
	|> Signal.register(name)
	:ok
end

prop_ts3 = fn name, ts1, ts2, ts3 ->
	sts1 = Signal.signal(ts1)
	sts2 = Signal.signal(ts2)
	sts3 = Signal.signal(ts3)
	p = Signal.liftapp([sts1, sts2, sts3], 
		fn x, y, z -> 
			Enum.max_by([x, y, z], fn {xn, xt} -> xt end) 
		end)
	|> Signal.register(name)
	:ok
end

prop_ts4 = fn name, ts1, ts2, ts3, ts4 ->
	sts1 = Signal.signal(ts1)
	sts2 = Signal.signal(ts2)
	sts3 = Signal.signal(ts3)
	sts4 = Signal.signal(ts4)
	p = Signal.liftapp([sts1, sts2, sts3, sts4], 
		fn v, w, x, y -> 
			Enum.max_by([v, w, x, y], fn {xn, xt} -> xt) end)
	|> Signal.register(name)
	:ok
end

final = fn ts ->
	sts = Signal.signal(ts)
	|> Signal.liftapp(fn {xn, xt} -> [{xn, xt, :erlang.monotonic_time}] end)
	|> Behaviour.changes
	|> EventStream.scan(fn x, l -> l ++ x end)
	|> Signal.register(String.to_atom(Atom.to_string(ts) <> "res")
	:ok
end

g = GraphCreation.generateGraph(params)
cs = Commands.generateCommands(g, params)
Commands.interpretCommands(cs, {prop_ts1, prop_ts2, prop_ts3, prop_ts4, final})

:timer.sleep(Keyword.get(params, experiment_length))

vars = Graph.getVars(g)
finals = 
	vars 
	|> Enum.map(fn v -> Graph.getFinalsForVar(g, v) end)
finals_for_vars = 
	vars
	|> Stream.zip(finals)
	|> Enum.filter(fn {v, [f | ft]} -> f != v end)
{rvars, rfinals} = Enum.unzip(finals_for_vars)
ress = 
	rfinals
	|> Enum.map(fn fi -> String.to_atom(Atom.to_string(f) <> "res") end)
	|> Enum.map(fn fi -> Signal.signal(fi) end)
	|> Enum.map(fn es -> EvenStream.hold(es) end)
	|> Enum.map(fn bh -> Behaviour.evaluate(bh) end)
ress_for_vars = 
	rvars
	|> Stream.zip(ress)
	|> Enum.map(
	fn {var, resls} ->
		total_prop_delays = 
			resls
			|> Enum.map(
				fn resl -> 
					resl
					|> Enum.filter(fn {xn, xt, xr} -> xn == var end) 
					|> Enum.map(fn {xn, xt, xr} -> {xt, xr} end)
				end)
			|> Enum.concat
			|> Enum.group_by(fn {xt, xr} -> xt end)
			|> Map.to_list
			|> Enum.filter(fn {xt, xrs} -> Enum.count(xrs) == Enum.count(resls) end)
			|> Enum.map(fn {xt, xrs} -> Enum.max(xrs) - xt end)
		mean = Enum.sum(total_prop_delays) / Enum.count(total_prop_delays))
		{var, mean}
	end)
{vars, means} = Enum.unzip(ress_for_vars)
total_mean = Enum.sum(means) / Enum.count(means)
IO.puts("Mean total propagation delay: #{total_mean}")