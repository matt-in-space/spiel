defmodule ResumeWeb.Admin.DashboardLive do
  use ResumeWeb, :live_view

  alias Resume.Admin
  alias ResumeWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    stats = Admin.dashboard_stats()
    {:ok, assign(socket, stats: stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: "Admin"}]}>
      <.header>
        Admin
        <:subtitle>System dashboards and tools</:subtitle>
      </.header>

      <div class="stats stats-vertical sm:stats-horizontal border border-base-300 w-full mb-6">
        <div class="stat">
          <div class="stat-title">Users</div>
          <div class="stat-value text-lg">{@stats.total_users}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Resumes</div>
          <div class="stat-value text-lg">{@stats.total_resumes}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Versions</div>
          <div class="stat-value text-lg">{@stats.total_versions}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Popular Template</div>
          <div class="stat-value text-lg">
            {if @stats.most_popular_template, do: @stats.most_popular_template.template, else: "—"}
          </div>
          <div :if={@stats.most_popular_template} class="stat-desc">
            {@stats.most_popular_template.count} resumes
          </div>
        </div>
        <div class="stat">
          <div class="stat-title">Downloads</div>
          <div class="stat-value text-lg">{@stats.total_downloads}</div>
        </div>
      </div>

      <div class="grid gap-4">
        <.link
          navigate={~p"/admin/costs"}
          class="card bg-base-200 border border-base-300 hover:border-base-content/20 transition-colors"
        >
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-currency-dollar" class="size-5" /> API Costs
            </h2>
            <p class="text-base-content/70">
              Track API usage, costs per user, and call breakdowns.
            </p>
          </div>
        </.link>
        <.link
          navigate={~p"/admin/billing"}
          class="card bg-base-200 border border-base-300 hover:border-base-content/20 transition-colors"
        >
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-credit-card" class="size-5" /> Billing
            </h2>
            <p class="text-base-content/70">
              Revenue, payments, and user access management.
            </p>
          </div>
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
