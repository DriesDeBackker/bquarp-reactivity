defmodule Evaluation.Adaptations.SignalEval do
  @moduledoc false
  alias Evaluation.Adaptations.CombineWithGuaranteesEval
  alias Reactivity.Quality.Context
  alias Reactivity.Quality.Guarantee
  alias Observables.Obs
  alias Observables.GenObservable

  require Logger


  def liftapp_eval({_type, _sobs, _gs} = signal, func) do
    liftapp_eval([signal], func)
  end

  def liftapp_eval(signals, func) do
    inds = 0..(length(signals) - 1)

    # Tag each value from an observee with its respective index
    sobss =
      signals
      |> Enum.map(fn {_type, sobs, _gs} -> sobs end)
    tagged =
      Enum.zip(sobss, inds)
      |> Enum.map(fn {sobs, index} ->
        sobs
        # |> Observables.Obs.inspect()
        |> Obs.map(fn msg -> {:newvalue, index, msg} end)
      end)

    # Create the arguments
    gss =
      signals
      |> Enum.map(fn {_type, _sobs, gs} -> gs end)
    gmap =
      inds
      |> Enum.zip(gss)
      |> Map.new()
    imap =
      inds
      |> Enum.map(fn i -> {i, []} end)
      |> Map.new()
    ts =
      signals
      |> Enum.map(fn {t, _, _} -> t end)
    tmap =
      inds
      |> Enum.zip(ts)
      |> Map.new()
    rtype =
      if contains_event_stream(signals) do
        :event_stream
      else
        :behaviour
      end

    # Start our CombineWithGuarantees observable.
    {:ok, pid} = GenObservable.start(CombineWithGuaranteesEval, [imap, tmap, gmap, rtype])
    # Make the observees send to us.
    tagged |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)
    # Create the continuation.
    cobs = {fn observer -> GenObservable.send_to(pid, observer) end, pid}

    # Apply the function to the combined observable
    # ADAPTATION: THE RESULT IS NOT RETURNED, BUT ONLY THE VALUE OF THE RECEIVED MESSAGE
    aobs =
      cobs
      |> Obs.map(fn {vals, eval, cxts} ->
        apply(func, vals)
        {eval, cxts}
      end)

    # Determine the resulting guarantees
    gs = Guarantee.combine(gss)
    # Establish the resulting observable
    robs = 
      case gs do
        [] -> 
          aobs
        _  -> 
          # Apply the appropriate transformations to the contexts
          tobs =
            gs
            |> Enum.map(fn g -> Context.new_context_obs(aobs, g) end)
            |> Obs.zip_n()
          aobs
          |> Obs.zip(tobs)
          |> Obs.map(
            fn {{v, cxs}, ts} ->
              tslist = Tuple.to_list(ts)
              new_cxs = Context.transform(cxs, tslist, gs)
              {v, new_cxs}
            end)
      end

    {rtype, robs, gs}
  end

  defp contains_event_stream([]), do: false
  defp contains_event_stream([{:event_stream, _, _} | _st]), do: true
  defp contains_event_stream([{:behaviour, _, _} | st]), do: contains_event_stream(st)
end