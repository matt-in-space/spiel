defmodule Resume.Retry do
  @moduledoc """
  Simple retry wrapper for operations that return `{:ok, _}` / `{:error, _}`.
  """

  require Logger

  @doc """
  Retries `fun` up to `max_attempts` times with `delay` ms between attempts.

  Defaults to 2 attempts (1 retry) with a 1-second delay.
  """
  def with_retry(fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, 2)
    delay = Keyword.get(opts, :delay, 1_000)
    do_retry(fun, max_attempts, delay, 1)
  end

  defp do_retry(fun, max, _delay, attempt) when attempt >= max do
    fun.()
  end

  defp do_retry(fun, max, delay, attempt) do
    case fun.() do
      {:ok, _} = result ->
        result

      {:error, :limit_reached, _} = result ->
        result

      {:error, reason} ->
        Logger.warning("Retry attempt #{attempt}/#{max} failed: #{inspect(reason)}")
        Process.sleep(delay)
        do_retry(fun, max, delay, attempt + 1)
    end
  end
end
