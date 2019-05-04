defmodule Reactivity.Quality.Guarantee do
	@moduledoc """
	Essential operations on guarantees.
	For every guarantee, the function semantics needs to be implemented.
	"""
	@doc """
	Returns the propagation semantics of a guarantee or set of guarantees.
	"""
	def semantics({:fu,	_}), do: 	semantics(:fu)
	def semantics({:c, _}), do: 	semantics(:c)
	def semantics({:g, _}), do: 	semantics(:g)
	def semantics({:fp, _}), do: 	semantics(:fp)
	def semantics({:t, _}), do: 	semantics(:t)
	def semantics(:fu), do: :update
	def semantics(:c), do: 	:update
	def semantics(:g), do: 	:update
	def semantics(:fp), do: :propagate
	def semantics(:t), do: 	:propagate
	def semantics(gs) do
		sems = gs
		|> Enum.map(fn {cgt, _cgm} -> semantics(cgt) end)
		propagate? = sems
		|> Enum.any?(fn s -> s == :propagate end)
		case propagate? do
			true -> :propagate
			false -> :update
		end
	end

	@doc """
	Combines lists of consistency guarantees.
	"""
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