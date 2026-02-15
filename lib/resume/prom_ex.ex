defmodule Resume.PromEx do
  @moduledoc """
  PromEx configuration for Prometheus metrics.

  Exposes BEAM, Phoenix, and Ecto metrics on a standalone server
  for Fly.io's managed Prometheus to scrape.
  """

  use PromEx, otp_app: :resume

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: ResumeWeb.Router, endpoint: ResumeWeb.Endpoint},
      {Plugins.Ecto, repos: [Resume.Repo]}
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"}
    ]
  end
end
