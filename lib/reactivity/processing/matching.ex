defmodule Reactivity.Processing.Matching do
  @moduledoc false
  alias Reactivity.Quality.Context
  alias Reactivity.Quality.Guarantee
  require Logger

  @doc """
  Matches the message with the contents of the buffer if possible, 
  respecting all consistency guarantees
  Dispenses with old messages to create a new buffer.

  ## Takes 
    * an input buffer 
      %{i => [msg]}
    * a message 
      {value, [context]}
    * the index of the parent signal that sent the message
    * the guarantees of the parent signals
      %{i => [g]}

  ## Returns {:ok, match, contexts, new_input_buffer} if succesful
    * match: a list of values for all signals in order
      [value]
    * contexts: the resulting contexts after combining the contexts of all matched messages
    * the new input buffer with previous data and matched messages from signals with 'propagate semantics' removed.
  Returns `:nomatch` if unsuccesful
  """
  def match(b, msg, i, tmap, gmap) do
    {fqs, fks, fts, fgs, mcgs} = preprocess(b, i, tmap, gmap)
    case imatch_(fqs, fgs, msg, mcgs) do
      {:ok, match, contexts, split_queues} ->
        complete_match = List.insert_at(match,i, msg)
        new_b = postprocess(split_queues, b, fks, msg, i, tmap, fts)
        {:ok, complete_match, contexts, new_b}
      {:err, _reason} ->
        :nomatch
    end
  end

  @doc """
  Takes an input buffer as a map of queue lists and the parent id of the message to match the buffer with.
  Outputs a list of queue lists and a corresponding list of parent ids without the entry for the message's parent
  %{0 => q0, ... , parent_id => q_parent_id, ... , n => qn}  -> {[q0, ... q_parent_id_-1, q_parent_id+1, ... , qn], [0, ... parent_id-1, parent_id+1, ... n]}
  """
  defp preprocess(b, i, ts, gs) do
    mcgs =
      gs
      |> Map.get(i)
    ks =
      b
      |> Map.keys()
      |> Enum.sort()
    fks =
      ks
      |> List.delete(i)
    fts =
      fks
      |> Enum.map(fn n -> Map.get(ts, n) end)
    fgs =
      fks
      |> Enum.map(fn n -> Map.get(gs, n) end)
    fqs =
      fks
      |> Enum.map(fn n -> Map.get(b, n) end)
      |> reverse(fts)
    {fqs, fks, fts, fgs, mcgs}
  end

  @doc """
  Takes: 
  - a list of input queues [{[msg], [msg]}] that are split at the matched message.
    * after standardization, each queue has the format {previous_message, [matched_message | later_messages]}
    * standardization is needed because some guarantees require a search beginning at the back of the queue 
      instead of at the front, yielding a different output format.
    * the queue of the message's parent is not part of this list.
  - a list of local parent ids [key] corresponding to the queues
    * the id of the message's parent is not part of this list.
  - the original input buffer
  - the local id of the parent that sent the message
  - the guarantees of each signal.
  Outputs: 
  - the new input buffer, which
     * in each queue list contains no messages before the message that is matched in that buffer.
     * contains only messages after that matched message if the guarantee type requires that the input be consumed.
  """
  defp postprocess(split_qs, b, fks, msg, i, tmap, fts) do
    remainder_qs =
      split_qs
      |> standardize(fts)
      |> Enum.map(&elem(&1, 1))
    new_parent_q = [msg]
    completed_ks =
      [i | fks]
      |> Enum.sort()
    position =
      completed_ks
      |> Enum.find_index(fn x -> x == i end)
    ks =
      b
      |> Map.keys()
      |> Enum.sort()
    tslist =
      ks
      |> Enum.map(fn n -> Map.get(tmap, n) end)
    completed_qs =
      remainder_qs
      |> List.insert_at(position, new_parent_q)
      |> consume(tslist)
    new_b =
      completed_ks
      |> Enum.zip(completed_qs)
      |> Map.new()
    new_b
  end

  #######################
  # MATCHING ALGORITHMS #
  #######################

  defp imatch_([], _fgs, {_v, c}, mcgs), do: {:ok, [], Context.combine([c], [mcgs]), []}
  defp imatch_(fqs, fgs, msg, mcgs) do
    [tq | tqs] = Enum.map(fqs, fn q -> {[], q} end)
    [fgsc | fgsn] = fgs
    imatch_([], tq, tqs, [], msg, {[], fgsc, fgsn}, mcgs)
  end

  defp imatch_(_qls, {[], []}, _qns, _acc, _msg, {_fgsl, _fgsc, _fgsn}, _mcgs) do
    # one queue is empty, no match possible
    {:err, :emptyqueue}
  end
  defp imatch_(qls, {mls, []}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs) do
    # We backtracked but this queue is out of messages.
    case qls do
      # There is a previous queue. Backtrack to that queue.
      [{qlsh_mls, [qlsh_mc | qlsh_mns]} | qlst] ->
        [_acch | acct] = acc
        [fgslh | fgslt] = fgsl
        imatch_(qlst, {[qlsh_mc | qlsh_mls], qlsh_mns}, [{[], Enum.reverse(mls)} | qns],
          acct, msg, {fgslt, fgslh, [fgsc | fgsn]}, mcgs)
      # There is no previous queue before the current one. # Search finished: no match found.
      [] ->
        {:err, :nomatch}
    end
  end
  defp imatch_(qls, {mls, [{mc, :ok} | mns]}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs) do
    cctxs =
      [msg | [mc | acc]]
      |> Enum.map(fn {_v, cs} -> cs end)
      |> Context.combine([mcgs | [fgsc | fgsl]])
    cgs = Guarantee.combine([mcgs | [fgsc | fgsl]])

    if Context.sufficient_quality?(cctxs, cgs) do
      # The current message we are considering can be matched with the array of messages matched so far.
      case qns do
        # There is still another queue left to match with. Proceed with that queue.
        [qnsh | qnst] ->
          [fgsnh | fgsnt] = fgsn
          imatch_(
            [{mls, [mc | mns]} | qls], qnsh, qnst, 
            [mc | acc], msg, {[fgsc | fgsl], fgsnh, fgsnt}, mcgs)
        # There is not further queue to match with. Search finished: match found.
        [] ->
          {:ok, Enum.reverse([mc | acc]), cctxs,
           Enum.reverse([{mls, [mc | mns]} | qls]) |> cut_tuples}
      end
    else
      # The current message won't do.
      case mns do
        # There is still a message left in the current queue. Proceed with that one.
        [_msnh | _msnt] ->
          imatch_(qls, {[mc | mls], mns}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs)
        # This queue is out of messages.
        [] ->
          case qls do
            # There is a previous queue. Backtrack to that queue.
            [{qlsh_mls, [qlsh_mc | qlsh_mns]} | qlst] ->
              [_acch | acct] = acc
              [fgslh | fgslt] = fgsl
              imatch_(qlst, {[qlsh_mc | qlsh_mls], qlsh_mns}, [{[], Enum.reverse([mc | mls])} | qns],
               acct, msg, {fgslt, fgslh, [fgsc | fgslt]}, mcgs)
            # There is no previous queue before the current one. # Search finished: no match found.
            [] ->
              {:err, :nomatch}
          end
      end
    end
  end
  defp imatch_(qls, {mls, [{mc, :bad} | [_msnh | _msnt] = mns]}, qns, 
    acc, msg, {fgsl, fgsc, fgsn}, mcgs) do
    # message is no use, go to the next one since there still is one in this queue.
    imatch_(qls, {[mc | mls], mns}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs)
  end
  defp imatch_([{qlsh_mls, [qlsh_mc | qlsh_mns]} | qlst], {mls, [{mc, :bad} | []]}, qns,
   [_acch | acct], msg, {[fgslh | fgslt], fgsc, fgsn}, mcgs) do
    # backtrack
    imatch_(qlst, {[qlsh_mc | qlsh_mls], qlsh_mns}, [{[], Enum.reverse([mc | mls])} | qns], 
      acct, msg, {fgslt, fgslh, [fgsc | fgsn]}, mcgs) 
  end
  defp imatch_([], {_mls, [{_mc, :bad} | []]}, _qns, _acc, _msg, _fgs, _mcgs), do: {:err, :nomatch}
  defp imatch_(qls, {mls, [mc | mns]}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs) do
    small_cctxs =
      [msg, mc]
      |> Enum.map(fn {_v, cs} -> cs end)
      |> Context.combine([mcgs, fgsc])
    cgs = Guarantee.combine([mcgs, fgsc])
    if Context.sufficient_quality?(small_cctxs, cgs) do
      imatch_(qls, {mls, [{mc, :ok} | mns]}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs)
    else
      imatch_(qls, {mls, [{mc, :bad} | mns]}, qns, acc, msg, {fgsl, fgsc, fgsn}, mcgs)
    end
  end

  ###########
  # HELPERS #
  ###########

  defp cut_tuples(split_queues) do
    cleanup = fn
      {msg, :ok} -> msg
      {msg, :bad} -> msg
      msg -> msg
    end
    split_queues
    |> Enum.map(fn {ql, qr} ->
      new_ql =
        ql
        |> Enum.map(fn el -> cleanup.(el) end)
      new_qr =
        qr
        |> Enum.map(fn el -> cleanup.(el) end)
      {new_ql, new_qr}
    end)
  end

  defp reverse(queues, fts) do
    rlist =
      fts
      |> Stream.map(fn
        :behaviour -> true
        :event_stream -> false
      end)
    queues
    |> Stream.zip(rlist)
    |> Enum.map(fn
      {q, true} -> Enum.reverse(q)
      {q, false} -> q
    end)
  end

  defp standardize(split_queues, fts) do
    slist =
      fts
      |> Stream.map(fn
        :behaviour -> true
        :event_stream -> false
      end)
    split_queues
    |> Stream.zip(slist)
    |> Enum.map(fn
      {{fst, [m | snd]}, true} -> {snd, [m | fst]}
      {split_queue, false} -> split_queue
    end)
  end

  defp consume(qs, tslist) do
    clist =
      tslist
      |> Stream.map(fn
        :behaviour -> false
        :event_stream -> true
      end)
    qs
    |> Stream.zip(clist)
    |> Enum.map(fn
      {[_m | rest], true} -> rest
      {q, false} -> q
    end)
  end
end