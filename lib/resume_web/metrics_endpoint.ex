defmodule ResumeWeb.MetricsEndpoint do
  @moduledoc """
  Lightweight Bandit server on a separate port for Prometheus metrics.

  Fly.io's metrics scraper hits machines directly (no proxy), which causes
  Plug.SSL on the main endpoint to redirect /metrics requests. Running
  metrics on a dedicated port avoids that entirely.
  """

  use Plug.Router

  plug :match
  plug :dispatch

  get "/metrics" do
    metrics = PromEx.get_metrics(Resume.PromEx)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
