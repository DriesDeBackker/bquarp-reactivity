defmodule Quality.BQuarp.Guarantee do

	def semantics(:fu), do: :update
	def semantics(:c), do: 	:update
	def semantics(:g), do: 	:update
	def semantics(:fp), do: :propagate
	def semantics(:t), do: 	:propagate

	def semantics({:fu,	_}), do: 	:update
	def semantics({:c, _}), do: 	:update
	def semantics({:g, _}), do: 	:update
	def semantics({:fp, _}), do: 	:propagate
	def semantics({:t, _}), do: 	:propagate

	def semantics(gs) do
		sems = gs
		|> Enum.map(fn {cgt, cgm} -> semantics(cgt) end)
		propagate? = sems
		|> Enum.any?(fn s -> s == :propagate end)
		case propagate? do
			true -> :propagate
			false -> :update
		end
	end
	
	def combine(gss) do
		gss
		|> List.flatten
		|> Enum.group_by(fn {g, _m} -> g end)
		|> Map.values
		|> Enum.map(
			fn gs ->
				Enum.min_by(gs, fn {_g, m} -> m end)
			end)
		|> List.flatten
	end
end