defmodule ResumeWeb.Admin.BillingLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Billing}

  @impl true
  def mount(_params, _session, socket) do
    stats = Billing.payment_stats()
    payments = Billing.list_recent_payments()

    {:ok,
     socket
     |> assign(
       stats: stats,
       search_query: "",
       search_results: [],
       page_title: "Admin: Billing"
     )
     |> stream(:payments, payments)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: "Admin", to: ~p"/admin"}, %{label: "Billing"}]}>
      <.header>
        Admin: Billing
        <:subtitle>Revenue, payments, and access management</:subtitle>
      </.header>

      <div class="stats stats-vertical sm:stats-horizontal border border-base-300 w-full mb-6">
        <div class="stat">
          <div class="stat-title">Total Revenue</div>
          <div class="stat-value text-lg">{format_dollars(@stats.total_revenue_cents)}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Paying Users</div>
          <div class="stat-value text-lg">{@stats.paying_user_count}</div>
        </div>
      </div>

      <div class="card bg-base-200 border border-base-300 mb-6">
        <div class="card-body">
          <h2 class="card-title text-lg">Grant / Revoke Unlimited Access</h2>
          <form phx-submit="search_users" class="flex gap-2 mt-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search by email..."
              class="input input-bordered input-sm flex-1"
            />
            <button type="submit" class="btn btn-sm btn-primary">Search</button>
          </form>

          <div :if={@search_results != []} class="mt-3 space-y-2">
            <div
              :for={user <- @search_results}
              class="flex items-center justify-between bg-base-100 rounded-lg p-3"
            >
              <div>
                <p class="text-sm font-medium">{user.email}</p>
                <p class="text-xs opacity-70">
                  Access: {user.access_level}
                  {if user.pass_expires_at,
                    do: " · Pass expires: #{format_date(user.pass_expires_at)}",
                    else: ""}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  :if={user.access_level != "unlimited"}
                  phx-click="grant_unlimited"
                  phx-value-user-id={user.id}
                  class="btn btn-xs btn-success"
                >
                  Grant Unlimited
                </button>
                <button
                  :if={user.access_level == "unlimited"}
                  phx-click="revoke_unlimited"
                  phx-value-user-id={user.id}
                  class="btn btn-xs btn-warning"
                >
                  Revoke Unlimited
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <h2 class="text-lg font-semibold mb-2">Recent Payments</h2>
      <.table id="payments" rows={@streams.payments}>
        <:col :let={{_id, p}} label="Date">{format_timestamp(p.inserted_at)}</:col>
        <:col :let={{_id, p}} label="User">{p.user.email}</:col>
        <:col :let={{_id, p}} label="Amount">{format_dollars(p.amount_cents)}</:col>
        <:col :let={{_id, p}} label="Status">{p.status}</:col>
        <:col :let={{_id, p}} label="Session ID">
          <span class="text-xs font-mono opacity-70">
            {String.slice(p.stripe_checkout_session_id, 0..20)}...
          </span>
        </:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    query = String.trim(query)
    results = if query == "", do: [], else: Billing.search_users(query)
    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  @impl true
  def handle_event("grant_unlimited", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Billing.grant_unlimited(user) do
      {:ok, _user} ->
        results = Billing.search_users(socket.assigns.search_query)

        {:noreply,
         socket
         |> assign(search_results: results)
         |> put_flash(:info, "Granted unlimited access to #{user.email}.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to grant access.")}
    end
  end

  @impl true
  def handle_event("revoke_unlimited", %{"user-id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    case Billing.revoke_unlimited(user) do
      {:ok, _user} ->
        results = Billing.search_users(socket.assigns.search_query)

        {:noreply,
         socket
         |> assign(search_results: results)
         |> put_flash(:info, "Revoked unlimited access for #{user.email}.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to revoke access.")}
    end
  end

  defp format_dollars(cents) when is_number(cents) do
    "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  end

  defp format_dollars(_), do: "$0.00"

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  defp format_timestamp(dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end
end
