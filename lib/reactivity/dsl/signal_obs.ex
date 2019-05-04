defmodule Reactivity.DSL.SignalObs do
	@moduledoc false
	alias Observables.Obs
	alias Reactivity.Quality.Context

	@doc """
	Turns a plain observable into a signal observable
	by wrapping each of its values v into a tuple {v, []},
	the empty list being a list of potential contexts.
	"""
	def from_plain_obs(obs) do
		obs
		|> Obs.map(fn v -> {v, []} end)
	end

	@doc """
	Turns a signal observable back into a plain observable
	by unwrapping each of its values v from its encompassing tuple {v, c},
	effectively stripping it from any associated contexts it might have.
	"""
	def to_plain_obs(sobs) do
		{vobs, _cobs} = sobs
		|> Obs.unzip
		vobs
	end

	@doc """
	Transforms a signal observable to an observable carrying only its contexts
	"""
	def to_context_obs(sobs) do
		{_vobs, cobs} = sobs
		|> Obs.unzip
		cobs
	end

	@doc """
	Adds the appropriate contexts to a signal observable for the given consistency guarantee
	The context is added to the back of the list of contexts [c]
	that is part of the tuple {v, [c]}, the value format of a signal observalbe
	"""
	def add_context(sobs, cg) do
		acobs = Context.new_context_obs(sobs, cg)
		{vobs, cobs} = sobs
		|> Obs.unzip
		ncobs = cobs
		|> Obs.zip(acobs)
		|> Obs.map(fn {pc, ac} -> pc ++ [ac] end)
		Obs.zip(vobs, ncobs)
	end

	@doc """
	Removes a context from a signal observable by its index.
	"""
	def remove_context(sobs, i) do
		sobs
		|> Obs.map(fn {v, cs} ->
			new_cs = cs
			|> List.delete_at(i)
			{v, new_cs} end)
	end

	@doc """
	Removes all contexts from the signal observable, safe for the one at the given index.
	"""
	def keep_context(sobs, i) do
		sobs
		|> Obs.map(fn {v, cs} ->
			c = cs
			|> Enum.at(i)
			new_cs = [c]
			{v, new_cs} end)
	end

	@doc """
	Removes all contexts from the signal observable.
	"""
	def clear_context(sobs) do
		sobs
		|> Obs.map(fn {v, _c} -> {v, []} end)
	end

	@doc """
	Sets the appropriate contexts of a signal observable for the given consistency guarantee.
	Replaces all existing contexts.
	"""
	def set_context(sobs, cg) do
		sobs
		|> clear_context
		|> add_context(cg)
	end

end