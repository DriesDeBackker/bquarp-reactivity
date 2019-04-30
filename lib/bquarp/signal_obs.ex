defmodule BQuarp.SignalObs do
	alias Observables.Obs
	alias BQuarp.Context

	@doc """
	Turns a plain observable into a signal observable
	by wrapping each of its values v into a tuple {v, []},
	the empty list being a list of potential contexts.
	"""
	def from_obs(obs) do
		obs
		|> Obs.map(fn v -> {v, []} end)
	end

	@doc """
	Turns a signal observable back into a plain observable
	by unwrapping each of its values v from its encompassing tuple {v, c},
	effectively stripping it from any associated contexts it might have.
	"""
	def to_plain_obs(obs) do
		{vobs, _cobs} = obs
		|> Obs.unzip
		vobs
	end

	@doc """
	Adds the appropriate contexts to a signal observable for the given consistency guarantee
	The context is added to the back of the list of contexts [c]
	that is part of the tuple {v, [c]}, the value format of a signal observalbe
	"""
	def add_context(obs, cg) do
		acobs = Context.new_context_obs(obs, cg)
		{vobs, cobs} = obs
		|> Obs.unzip
		ncobs = cobs
		|> Obs.zip(acobs)
		|> Obs.map(fn {pc, ac} -> [ac | pc] end)
		Obs.zip(vobs, ncobs)
	end

	@doc """
	Removes a context from a signal observable by its index.
	"""
	def remove_context(obs, i) do
		obs
		|> Obs.map(fn {v, cs} ->
			new_cs = cs
			|> List.delete_at(i)
			{v, new_cs} end)
	end

	@doc """
	Removes all contexts from the signal observable, safe for the one at the given index.
	"""
	def keep_context(obs, i) do
		obs
		|> Obs.map(fn {v, cs} ->
			c = cs
			|> Enum.at(i)
			new_cs = [c]
			{v, new_cs} end)
	end

	@doc """
	Removes all contexts from the signal observable.
	"""
	def clear_context(obs) do
		obs
		|> Obs.map(fn {v, _c} -> {v, []} end)
	end

	@doc """
	Sets the appropriate contexts of a signal observable for the given consistency guarantee.
	Replaces all existing contexts.
	"""
	def set_context(obs, cg) do
		obs
		|> clear_context
		|> add_context(cg)
	end
end