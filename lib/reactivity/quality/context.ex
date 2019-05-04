defmodule Reactivity.Quality.Context do
	@moduledoc """
	Essential operations on message contexts.
	For every guarantee, the functions combine, penalty and transform need to be implemented.
	Guarantees with obvious context-progression (e.g. with counters) should implement new_context_obs.
	"""
	alias Observables.Obs
	alias Reactivity.Quality.Guarantee
	require Logger

	################################
	###### COMBINING CONTEXTS ######
	# (INTO INTERMEDIATE CONTEXTS) #
	################################

	@doc """
	Combines a list of contexts in the case of enforcing fifo with propagate semantics

	Takes a list of fifo contexts: 
	[nil]

	Returns an intermediate fifo context (which is also a finalized fifo-context
	by virtue of the transformation for fifo being the identity):
	nil
	"""
	def combine(contexts, {:fp, _}), do: combine(contexts, :fp)
	def combine(_contexts, :fp), do: nil

	@doc """
	Combines a list of contexts in the case of enforcing fifo with update semantics
	Takes a list of fifo contexts: [nil]
	Returns a fifo context: nil
	"""
	def combine(contexts, {:fu, _}), do: combine(contexts, :fu)
	def combine(_contexts, :fu), do: nil

	@doc """
	combines a list of contexts in the case of enforcing time synchronization (clock-difference)

	Takes a list of time-synchronization contexts:
	[stamp(s)] with stamp(s) = stamp | {lowest_stamp, highest_stamp}

	Returns an intermediate time-synchronization context 
	(which is also a finalized time-synchronization context
	by virtue of the transformation for time-synch being the identity):
	stamp(s)

	The lowest and highest timestamp get recalculated from all the stamp(s)s in the list.
	[{4, 5}, 2, 3, {3, 6}] -> {2, 6}
	"""
	def combine(contexts, {:t, _}), do: combine(contexts, :t)
	def combine(contexts, :t) do
		lows = contexts |> Stream.map(fn 
			{low, _high}	-> low
			time 					-> time 
		end)
		highs = contexts |> Stream.map(fn
			{_low, high}	-> high
			time 					-> time
		end)
		{low, high} = {Enum.min(lows), Enum.max(highs)}
		if (low == high), do: low, else: {low, high}
	end

	@doc """
	combines a list of contexts in the case of enforcing glitch freedom

	Takes a list of glitch-freedom contexts
	[[{source, counter(s)}]] with counter(s) = counter | {lowest_counter, highest_counter}

	Returns a an intermediate glitch-freedom context 
	(which is also a finalized glitch-freedom context
	by virtue of the transformation for glitch-freedom being the identity):
	[{source, counter(s)}]

	For each source, the lowest and highest counter gets recalculated from all the tuples {source, counter(s)} with that source.
	If those are the same, only one counter value is present.

	E.g.: 
	[{:a, 5}, {:a, 4}, {:b, 11}, {:c, {1, 2}}, {:c, 3}] -> [{:a, {4, 5}}, {:b, 11}, {:c, {1, 3}}]
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
	Combines a list of contexts in the case of enforcing causality

	Takes a list of causality contexts:
	[c] (with c = path = [tree | [{node, counter}]] | [{node, counter}])

	Returns an intermediate causality context: ic = [c]
	"""
	def combine(contexts, {:c, _}), do: combine(contexts, :c)
	def combine(contexts, :c), do: contexts

	@doc """
	Combines multiple lists of contexts of possibly different consistency guarantees by combining
	the contexts pertaining to each occurring guarantee type separately.
	Takes 
	* a list of context lists [[c]]]
	* a list of guarantee lists [[g]]]
	Returns a list of contexts [c]
	"""
	def combine(contextss, guaranteess) do
		guaranteess
		|> Enum.zip(contextss)
		|> Enum.map(fn {guarantees, contexts} -> 
			Enum.zip(guarantees, contexts) end)
		|> List.flatten
		|> Enum.group_by(fn {{cgt, _cgm}, _ac} -> cgt end)
		|> Map.values
		|> Stream.map(fn lst -> Enum.unzip(lst) end)
		|> Enum.map(fn {gs, cs} -> 
			[g] = Guarantee.combine(gs)
			c = combine(cs, g)
			c end)
	end

	##############################################
	# DETERMINING (INTERMEDIATE) CONTEXT QUALITY #
	##############################################

	@doc """
	Decides whether the given list of contexts accompanied by their respective guarantees
	is acceptable under these guarantees.

	Returns true or false
	The given list of contexts is of sufficient qualityif for every context, it satisfies the accompanying guarantee.
	"""
	def sufficient_quality?([], _gs), do: true
	def sufficient_quality?([ch | ct], [gh | gt]) do
		sufficient_quality?(ch, gh) and sufficient_quality?(ct, gt)
	end

	@doc """
	Decides whether a given context is acceptable under the given consistency guarantee.
	"""
	def sufficient_quality?(context, {cgt, cgm}) do
		penalty(context, cgt) <= cgm
	end

	#############################################

	@doc """
	Calculates the penalty of a context in the case of enforcing fifo with propagate semantics
	"""
	def penalty(context, {:fp, _}), do: penalty(context, :fp)
	def penalty(_context, :fp), do: 0

	@doc """
	Calculates the penalty of a context in the case of enforcing fifo with update semantics
	"""
	def penalty(context, {:fu, _}), do: penalty(context, :fu)
	def penalty(_context, :fu), do: 0

	@doc """
	calculates the penalty of a context in the case of enforcing time-synchronization.
	Takes a context of the form t or {t_low, t_high} and calculates the difference.
	"""
	def penalty(context, {:t, _}), do: penalty(context, :t)
	def penalty({low, high}, :t), do: high-low
	def penalty(_time, :t), do: 0

	@doc """
	calculates the penalty of a context in the case of enforcing glitch freedom
	Takes a context of the form [{si, ci}] with si = counter_i | {lowest_counter_i, highest_counter_i}
	And returns the maximum difference between counters attached to the same source.
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
	calculates the penalty of a context in the case of enforcing causality.

	Compares paths/trees in the context two by two and takes the maximum penalty from all comparisons
	Two paths/trees may have a nonzero penalty if one is a prefix of the other.
	Then we must compare the counter produced by the last shared node in order to determine
	if the longer path does not reflect a later update than the prefix path, violating causality.
	"""
	def penalty(context, {:c, _}), do: penalty(context, :c)
	def penalty([_ch | []], :c), do: 0
	def penalty([ch | ct], :c) do
		pch = ct
		|> Enum.map(fn ctc -> cpenalty(ch, ctc) end)
		|> Enum.max
		max(pch, penalty(ct, :c))
	end

	defp cpenalty([], []), do: 0
	defp cpenalty([{s, n1} | []], [{s, n2}, _ | _]), do: n2-n1
	defp cpenalty([{s, n1}, _ | _], [{s, n2} | []]), do: n1-n2
	defp cpenalty([{s, _n1} | c1t], [{s, _n2} | c2t]), do: cpenalty(c1t, c2t)
	defp cpenalty([{_s1, _n1} | _c1t], [{_s2, _n2} | _c2t]), do: 0
	defp cpenalty([c1h | _], [{_s, _n} | _] = c2) when is_list(c1h) do
		c1h
		|> Enum.map(fn ctc -> cpenalty(c2, ctc) end)
		|> Enum.max
	end
	defp cpenalty([{_s, _n} | _] = c1, [c2h | _]) when is_list(c2h) do
		c2h
		|> Enum.map(fn ctc -> cpenalty(c1, ctc) end)
		|> Enum.max
	end
	defp cpenalty([c1h | c1t], [c2h | c2t]) when is_list(c1h) and is_list(c2h) do
		cpenalty(c1t, c2t)
	end

	######################################
	# TRANSFORMING INTERMEDIATE CONTEXTS #
	###### (INTO FINALIZED CONTEXTS) #####
	######################################

	@doc """
	Transforms a list of intermediate contexts into finalized (i.e. plain) contexts
	according to their respective guarantees and by means of the given transformation data
	"""
	def transform([], [], []), do: []
	def transform([c | ct], [t | tt], [g | gt]) do
		[transform(c, t, g) | transform(ct, tt, gt)]
	end

	@doc """
	Transforms a fifo context (update semantics) by leaving it 'as is'.
	"""
	def transform(c, _trans, {:fu, _m}), do: c

	@doc """
	Transforms a fifo context (propagate semantics) by leaving it 'as is'.
	"""
	def transform(c, _trans, {:fp, _m}), do: c

	@doc """
	Transforms a time-synchronization context by leaving it 'as is'.
	"""
	def transform(c, _trans, {:t, _m}), do: c

	@doc """
	Transforms a glitch-freedom context by leaving it 'as is'.
	"""
	def transform(c, _trans, {:g, _m}), do: c

	@doc """
	Transforms a causality context.
	The transformation data is of the form {node, counter}

	If the context is a path of nodes [{node, counter}],
	just append the transformation data, completing the path.

	If the context is a list of paths
	"""
	def transform(c, trans, {:c, _m}) do
		case c do
			[[_ | _]=path] 	-> path ++ trans
			[[_ | _] | _] 	-> [c] 	++ trans
		end
	end

	################################
	# CREATING CONTEXT OBSERVABLES #
	################################

	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable under fifo with update semantics.
	"""
	def new_context_obs(obs, {:fu, _m}) do
		Obs.count(obs, 0)
		|> Obs.map(fn _ -> nil end)
	end

	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable under fifo with propagate semantics.
	"""
	def new_context_obs(obs, {:fp, _m}) do
		Obs.count(obs, 0)
		|> Obs.map(fn _ -> nil end)
	end

	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable under glitch-freedom.
	"""
	def new_context_obs(obs, {:g, _m}) do
		{_f, pid} = obs
		Obs.count(obs, 0)
		|> Obs.map(fn n -> [{{node(), pid}, n-1}] end)
	end

	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable under time-synchronization.
	"""
	def new_context_obs(obs, {:t, _m}) do
		Obs.count(obs, 0)
		|> Obs.map(fn n ->  n-1 end)
	end

	@doc """
	Creates an observable carrying the contexts 
	for the respective values of a given observable under causality.
	"""
	def new_context_obs(obs, {:c, _m}) do
		{_f, pid} = obs
		Obs.count(obs, 0)
		|> Obs.map(fn n -> [{{node(), pid}, n-1}] end)
	end

end