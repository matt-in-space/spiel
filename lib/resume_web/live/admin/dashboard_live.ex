defmodule ResumeWeb.Admin.DashboardLive do
  use ResumeWeb, :live_view

  alias ResumeWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Admin
        <:subtitle>System dashboards and tools</:subtitle>
      </.header>

      <div class="grid gap-4">
        <.link
          navigate={~p"/admin/costs"}
          class="card bg-base-200 border border-base-300 hover:border-base-content/20 transition-colors"
        >
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-currency-dollar" class="size-5" /> LLM Costs
            </h2>
            <p class="text-base-content/70">
              Track LLM API usage, costs per user, and call breakdowns.
            </p>
          </div>
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
