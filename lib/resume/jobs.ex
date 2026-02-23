defmodule Resume.Jobs do
  @moduledoc """
  Tracks in-flight background jobs (e.g. resume/cover-letter generation)
  so they survive LiveView navigation.

  Jobs are run under `Resume.TaskSupervisor` (unlinked from the caller)
  and tracked in an ETS table. Completion is broadcast via PubSub so any
  LiveView that subscribes can pick up the result.
  """

  use GenServer

  @table __MODULE__
  @pubsub Resume.PubSub

  # ── Startup ─────────────────────────────────────────────────────────

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{}}
  end

  # ── Public API ──────────────────────────────────────────────────────

  @doc """
  Start a job if one isn't already running for `key`.

  Returns `:ok` if a new job was started, or `{:already_running, pid}`
  if one is already in-flight.
  """
  def start(key, fun) when is_function(fun, 0) do
    case :ets.insert_new(@table, {key, nil}) do
      true ->
        %{pid: pid} =
          Task.Supervisor.async_nolink(Resume.TaskSupervisor, fn ->
            result = fun.()
            finish(key, result)
            result
          end)

        :ets.update_element(@table, key, {2, pid})
        :ok

      false ->
        [{^key, pid}] = :ets.lookup(@table, key)
        {:already_running, pid}
    end
  end

  @doc "Check whether a job is currently in-flight for `key`."
  def running?(key) do
    :ets.member(@table, key)
  end

  @doc "Subscribe the caller to completion of `key`."
  def subscribe(key) do
    Phoenix.PubSub.subscribe(@pubsub, topic(key))
  end

  # ── Internals ───────────────────────────────────────────────────────

  defp finish(key, result) do
    :ets.delete(@table, key)
    Phoenix.PubSub.broadcast(@pubsub, topic(key), {:job_complete, key, result})
  end

  defp topic(key), do: "jobs:#{inspect(key)}"
end
