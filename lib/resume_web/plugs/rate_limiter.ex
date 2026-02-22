defmodule ResumeWeb.Plugs.RateLimiter do
  @moduledoc """
  A plug that rate-limits requests by client IP using `Resume.RateLimiter`.

  ## Options

    * `:key` — string prefix for the rate limit bucket (required)
    * `:scale` — time window in milliseconds (required)
    * `:limit` — max number of requests in the window (required)

  ## Example

      plug ResumeWeb.Plugs.RateLimiter,
        [key: "login", scale: :timer.minutes(15), limit: 5]
        when action in [:create]
  """

  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(opts) do
    %{
      key: Keyword.fetch!(opts, :key),
      scale: Keyword.fetch!(opts, :scale),
      limit: Keyword.fetch!(opts, :limit)
    }
  end

  def call(conn, %{key: key, scale: scale, limit: limit}) do
    if Application.get_env(:resume, :rate_limiting_enabled, true) do
      check_rate(conn, key, scale, limit)
    else
      conn
    end
  end

  defp check_rate(conn, key, scale, limit) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    bucket = "#{key}:#{ip}"

    case Resume.RateLimiter.hit(bucket, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, retry_after_ms} ->
        retry_after_seconds = div(retry_after_ms, 1000) |> max(1)

        conn
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> put_flash(:error, "Too many requests. Please try again later.")
        |> redirect(to: redirect_path(conn))
        |> halt()
    end
  end

  defp redirect_path(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
        %URI{path: path} = URI.parse(referer)
        path || conn.request_path

      [] ->
        conn.request_path
    end
  end
end
