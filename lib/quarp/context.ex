defmodule Quality.Quarp.Context do
	alias Observables.Obs
	require Logger

	def combine(_, nil), do: nil

	@doc """
	combines a list of contexts in the case of enforcing time synchronization
	Takes a mixed list of tuples {oldest_timestamp, newest_timestamp} and timestamps ti
	Returns a tuple containing the oldest, respectively the most recent timestamp in the list.
	[{tl1,th1}, t2, t3, {t4l, t4h}, ... , {tln,thn}] -> {tl_min, tl_max}
	"""
	def combine(contexts, {:t, _}), do: combine(contexts, :t)
	def combine(contexts, :t) do
		lows = contexts |> Stream.map(fn 
			{low, _high} -> low
			time 				-> time 
		end)
		highs = contexts |> Stream.map(fn
			{_low, high} -> high
			time 				-> time
		end)
		{low, high} = {Enum.min(lows), Enum.max(highs)}
		if (low == high), do: low, else: {low, high}
	end

	@doc """
	combines a list of contexts in the case of enforcing glitch freedom
	[[{s11,{c1low, c1high}},...,{s1n, c1n}], ... , [{sm1,cm1},...,{smn,cmn}]]-> [{sa, ca}, {sb,cb}, ...]
	Joins the list of contexts into one context of tuples {sender, counter}
	and removes duplicate tuples
	"""
	def combine(contexts, {:g, _}), do: combine(contexts, :g)
	def combine(contexts, :g) do
		contexts 
		|> List.flatten
		|> Enum.group_by(&(elem(&1,0)))
		|> Map.values
		|> Enum.map(fn 
			[h | []] -> h
			slst 		 -> 
				lows = slst |> Stream.map(fn 
					{_, {low, _}} -> low
					{_, counter}  -> counter
				end)
				highs = slst |> Stream.map(fn 
					{_, {_, high}} -> high
					{_, counter} 	 -> counter 
				end)
				s = slst |> List.first |> elem(0)
				{low, high} = {Enum.min(lows), Enum.max(highs)}
				c = if (low == high), do: low, else: {low, high}
				{s, c}
			end)
	end


	@doc """
	Decides whether a given context is acceptable under given consistency guarantee.
	"""
	def sufficient_quality?(context, {cgt, cgm}) do
		penalty(context, cgt) <= cgm
	end

	@doc """
	calculates the penalty of a context in the case of enforcing glitch freedom
	Takes a context of the form [{si, ci}] with si = counter_i | {lowest_counter_i, highest_counter_i}
	"""
	def penalty(context, {:g, _}), do: penalty(context, :g)
	def penalty(context, :g) do
		context
		|> Stream.map(fn 
				{_s, {low, high}} 	-> high-low
				{_s, _counter} 			-> 0
			end)
		|> Enum.max
	end

	@doc """
	calculates the penalty of a context in the case of enforcing time-synchronization
	"""
	def penalty(context, {:t, _}), do: penalty(context, :t)
	def penalty({low, high}, :t), do: high-low
	def penalty(_time, :t), do: 0


	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable and a given consistency guarantee.
	"""

	def new_context_obs(obs, :g) do
		Obs.count(obs, 0)
		|> Obs.map(fn n -> [{{node(), self()}, n}] end)
	end

	def new_context_obs(obs, :t) do
		Obs.count(obs, 0)
	end


	################### LEGACY CODE (remove in time) #####################

	def new({:t}) do
		timestamp = :erlang.monotonic_time()
		{timestamp, {:t}}
	end

	def new({:t, counter}) do
		{counter, {:t, counter + 1}}
	end

	def new({:g, counter, source_name}) do
		{[{{Node.self, source_name}, counter}], {:g, counter + 1, source_name}}
	end

	def new(nil), do: nil

end