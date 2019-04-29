defmodule Quality.Quarp do
	alias Observables.Obs
	alias Quality.Quarp.Context

	def process(obss, func, cg) do
		Obs.combine_n(obss)
		|> Obs.filter(generate_quality_predicate(cg))
		|> Obs.map(fn ctup -> applyfunc(ctup, func, cg) end)
	end

	defp generate_quality_predicate(cg) do
		fn ctup ->
			Tuple.to_list(ctup)
			|> Enum.map(fn {:value, _v, :context, c} -> c end)
			|> Context.combine(cg)
			|> Context.sufficient_quality?(cg)
		end
	end

	defp applyfunc(ctup, func, cg) do
		clist = Tuple.to_list(ctup)
		vals = clist
		|> Enum.map(fn {:value, v, :context, _c} -> v end)
		cts = clist
		|> Enum.map(fn {:value, _v, :context, c} -> c end)
		new_cxt = Context.combine(cts, cg)
		new_val = apply(vals, func)
		{:value, new_val, :context, new_cxt}
	end

end