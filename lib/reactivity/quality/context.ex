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
  1) Combines a list of contexts

  * In the case of causality:
  	- Takes a list of contexts [c] (with c = path = [tree | [{node, counter}]] | [{node, counter}])
  	- Returns an intermediate causality context i = [c]
  	-> Just leaves the list 'as is'.

  * In the case of glitch-freedom:
  	- Takes a list of contexts [[{source, counter(s)}]] with counter(s) = counter | {lowest_counter, highest_counter}
  	- Returns a an intermediate glitch-freedom context [{source, counter(s)}]
  	-> For each source, the lowest and highest counter gets recalculated from all the tuples {source, counter(s)} with that source.
  		 If those are the same, only one counter value is present.
  		 E.g.: [{:a, 5}, {:a, 4}, {:b, 11}, {:c, {1, 2}}, {:c, 3}] -> [{:a, {4, 5}}, {:b, 11}, {:c, {1, 3}}]

  * In the case of time-synchronization:
  	- Takes a list of time-synchronization contexts [stamp(s)] with stamp(s) = stamp | {lowest_stamp, highest_stamp}
  	- Returns an intermediate time-synchronization context 
  	-> The lowest and highest timestamp get recalculated from all the stamp(s)s in the list.
  		 E.g.: [{4, 5}, 2, 3, {3, 6}] -> {2, 6}

  2) Combines multiple lists of contexts of possibly different consistency guarantees
     This happens by combining the contexts pertaining to each occurring guarantee type separately.
  	 - Takes:
  	   * a list of context lists [[c]]]
  	   * a list of guarantee lists [[g]]]
  	 - Returns a list of intermediate contexts [i]

  """
  def combine(contexts, {:c, _}), do: combine(contexts, :c)
  def combine(contexts, :c), do: contexts

  def combine(contexts, {:g, _}), do: combine(contexts, :g)

  def combine(contexts, :g) do
    contexts
    |> List.flatten()
    |> Enum.group_by(&elem(&1, 0))
    |> Map.values()
    |> Enum.map(fn
      [h | []] ->
        h

      slst ->
        lows =
          slst
          |> Stream.map(fn
            {_, {low, _}} -> low
            {_, counter} -> counter
          end)

        highs =
          slst
          |> Stream.map(fn
            {_, {_, high}} -> high
            {_, counter} -> counter
          end)

        s = slst |> List.first() |> elem(0)
        {low, high} = {Enum.min(lows), Enum.max(highs)}
        c = if low == high, do: low, else: {low, high}
        {s, c}
    end)
  end

  def combine(contexts, {:t, _}), do: combine(contexts, :t)

  def combine(contexts, :t) do
    lows =
      contexts
      |> Stream.map(fn
        {low, _high} -> low
        time -> time
      end)

    highs =
      contexts
      |> Stream.map(fn
        {_low, high} -> high
        time -> time
      end)

    {low, high} = {Enum.min(lows), Enum.max(highs)}
    if low == high, do: low, else: {low, high}
  end

  # Combines multiple lists of contexts
  def combine(contextss, guaranteess) do
    guaranteess
    |> Enum.zip(contextss)
    |> Enum.map(fn {guarantees, contexts} ->
      Enum.zip(guarantees, contexts)
    end)
    |> List.flatten()
    |> Enum.group_by(fn {{cgt, _cgm}, _ac} -> cgt end)
    |> Map.values()
    |> Stream.map(fn lst -> Enum.unzip(lst) end)
    |> Enum.map(fn {gs, cs} ->
      [g] = Guarantee.combine(gs)
      c = combine(cs, g)
      c
    end)
  end

  ##############################################
  # DETERMINING (INTERMEDIATE) CONTEXT QUALITY #
  ##############################################

  @doc """
  Decides whether the given intermediate contexts are of acceptable quality for given guarantees.
  - Takes
    * A list of intermediate ontexts [i]
    * A list of associated guarantees [g] for the respective contexts
  - Returns whether the list of contexts is acceptable (true or false)
  -> The given list of intermediate contexts is of sufficient quality if for every context, 
     its penalty under the associated guarantee is less than or equal to the margin of that guarantee.
  """
  def sufficient_quality?([], _gs), do: true

  def sufficient_quality?([ih | it], [gh | gt]) do
    sufficient_quality?(ih, gh) and sufficient_quality?(it, gt)
  end

  def sufficient_quality?(i, {gt, gm}) do
    penalty(i, gt) <= gm
  end

  #############################################

  @doc """
  calculates the penalty of a context.

  * In the case of causality:
  	Compares paths/trees in the context two by two and takes the maximum penalty from all comparisons
  	Two paths/trees may have a nonzero penalty if one is a prefix of the other.
  	Then we must compare the counter produced by the last shared node in order to determine
  	if the longer path does not reflect a later update than the prefix path, violating causality.

  * In the case of glitch-freedom:
  	Takes a context of the form [{si, ci}] with si = counter_i | {lowest_counter_i, highest_counter_i}
  	And returns the maximum difference between counters attached to the same source.

  * In the case of time-synchronization:
    Takes a context of the form t or {t_low, t_high} and calculates the difference.
  """
  def penalty(i, {:c, _}), do: penalty(i, :c)
  def penalty([_ih | []], :c), do: 0

  def penalty([ih | it], :c) do
    pih =
      it
      |> Enum.map(fn itc -> cpenalty(ih, itc) end)
      |> Enum.max()

    max(pih, penalty(it, :c))
  end

  def penalty(i, {:g, _}), do: penalty(i, :g)

  def penalty(i, :g) do
    i
    |> Stream.map(fn
      {_s, {low, high}} -> high - low
      {_s, _counter} -> 0
    end)
    |> Enum.max()
  end

  def penalty(i, {:t, _}), do: penalty(i, :t)
  def penalty({low, high}, :t), do: high - low
  def penalty(_time, :t), do: 0

  # Helper function for penalty in case of causality. Calculates the actual penalty.
  defp cpenalty([], []), do: 0
  defp cpenalty([{s, n1} | []], [{s, n2}, _ | _]), do: n2 - n1
  defp cpenalty([{s, n1}, _ | _], [{s, n2} | []]), do: n1 - n2
  defp cpenalty([{s, _n1} | c1t], [{s, _n2} | c2t]), do: cpenalty(c1t, c2t)
  defp cpenalty([{_s1, _n1} | _c1t], [{_s2, _n2} | _c2t]), do: 0

  defp cpenalty([c1h | _], [{_s, _n} | _] = c2) when is_list(c1h) do
    c1h
    |> Enum.map(fn ctc -> cpenalty(c2, ctc) end)
    |> Enum.max()
  end

  defp cpenalty([{_s, _n} | _] = c1, [c2h | _]) when is_list(c2h) do
    c2h
    |> Enum.map(fn ctc -> cpenalty(c1, ctc) end)
    |> Enum.max()
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

  * In the case of causality: 
  	The transformation data is of the form {node, counter}
  	If the context is a path of nodes [{node, counter}],
  	just append the transformation data, completing the path.
  	If the context is a list of paths, that list is the first node of a new path,
  	and the transformation data gets appended as the second node, completing the path.

  * In the case of glitch-freedom:
    The transformation is the identity map

  * In the case of time-synchronization:
    The transformation is the identity map

  """
  def transform([], [], []), do: []

  def transform([i | it], [t | tt], [g | gt]) do
    [transform(i, t, g) | transform(it, tt, gt)]
  end

  def transform(i, trans, {:c, _m}) do
    case i do
      [[_ | _] = path] -> path ++ trans
      [[_ | _] | _] -> [i] ++ trans
    end
  end

  def transform(i, _trans, {:t, _m}), do: i

  def transform(i, _trans, {:g, _m}), do: i

  ################################
  # CREATING CONTEXT OBSERVABLES #
  ################################

  @doc """
  Creates an observable carrying the contexts 
  for the respective values of a given observable under the given guarantee.

  * In the case of causality: 
  	The source node identifier and a counter value: {s, c}

  * In the case of glitch-freedom:
  	The source node identifier and a counter value: {s, c}

  * In the case of time-synchronization:
    A counter value c
  """
  def new_context_obs(obs, {:g, _m}) do
    {_f, pid} = obs

    Obs.count(obs, 0)
    |> Obs.map(fn n -> [{{node(), pid}, n - 1}] end)
  end

  def new_context_obs(obs, {:t, _m}) do
    Obs.count(obs, 0)
    |> Obs.map(fn n -> n - 1 end)
  end

  def new_context_obs(obs, {:c, _m}) do
    {_f, pid} = obs

    Obs.count(obs, 0)
    |> Obs.map(fn n -> [{{node(), pid}, n - 1}] end)
  end
end
