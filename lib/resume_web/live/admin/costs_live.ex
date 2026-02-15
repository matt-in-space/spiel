defmodule ResumeWeb.Admin.CostsLive do
  use ResumeWeb, :live_view

  alias Resume.LLM.Costs
  alias ResumeWeb.Layouts

  @periods %{
    "today" => {0, "Today"},
    "7d" => {7, "7 Days"},
    "30d" => {30, "30 Days"},
    "all" => {nil, "All Time"}
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(period: "30d")
     |> load_data()}
  end

  @impl true
  def handle_event("change_period", %{"period" => period}, socket) do
    {:noreply,
     socket
     |> assign(period: period)
     |> load_data()}
  end

  defp load_data(socket) do
    since = since_for(socket.assigns.period)

    total_cents =
      case since do
        nil -> Costs.global_total_cents()
        dt -> Costs.global_total_cents_since(dt)
      end

    call_count = Costs.global_call_count(since)
    user_breakdown = Costs.user_cost_breakdown(since)
    caller_breakdown = Costs.caller_breakdown(since)
    recent_calls = Costs.global_recent_calls(50)

    avg_cost =
      if call_count > 0,
        do: total_cents / call_count,
        else: 0.0

    socket
    |> assign(
      total_cents: total_cents,
      call_count: call_count,
      avg_cost: avg_cost,
      user_breakdown: user_breakdown,
      caller_breakdown: caller_breakdown
    )
    |> stream(:recent_calls, recent_calls, reset: true)
  end

  defp since_for("today"), do: DateTime.utc_now() |> DateTime.add(-1, :day)

  defp since_for(period) do
    case @periods[period] do
      {nil, _} -> nil
      {days, _} -> DateTime.utc_now() |> DateTime.add(-days, :day)
    end
  end

  defp period_label(period), do: @periods[period] |> elem(1)

  defp format_dollars(cents) when is_number(cents) do
    "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  end

  defp format_dollars(_), do: "$0.00"

  defp format_timestamp(dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  defp user_email(%{user: %{email: email}}), do: email
  defp user_email(_), do: "—"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Admin: LLM Costs
        <:subtitle>Usage and cost tracking across all users</:subtitle>
      </.header>

      <div class="flex gap-2 mb-6">
        <button
          :for={key <- ~w(today 7d 30d all)}
          phx-click="change_period"
          phx-value-period={key}
          class={["btn btn-sm", key == @period && "btn-primary", key != @period && "btn-ghost"]}
        >
          {period_label(key)}
        </button>
      </div>

      <div class="stats stats-vertical sm:stats-horizontal shadow w-full mb-6">
        <div class="stat">
          <div class="stat-title">Total Cost</div>
          <div class="stat-value text-lg">{format_dollars(@total_cents)}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Total Calls</div>
          <div class="stat-value text-lg">{@call_count}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Avg Cost / Call</div>
          <div class="stat-value text-lg">{format_dollars(@avg_cost)}</div>
        </div>
      </div>

      <h2 class="text-lg font-semibold mb-2">Cost by User</h2>
      <.table id="user-breakdown" rows={@user_breakdown} row_id={&"user-#{&1.user_id}"}>
        <:col :let={row} label="Email">{row.email}</:col>
        <:col :let={row} label="Calls">{row.call_count}</:col>
        <:col :let={row} label="Total Cost">{format_dollars(row.total_cost_cents)}</:col>
      </.table>

      <h2 class="text-lg font-semibold mt-6 mb-2">Calls by Type</h2>
      <.table id="caller-breakdown" rows={@caller_breakdown} row_id={&"caller-#{&1.caller}"}>
        <:col :let={row} label="Caller">{row.caller || "—"}</:col>
        <:col :let={row} label="Calls">{row.call_count}</:col>
        <:col :let={row} label="Total Cost">{format_dollars(row.total_cost_cents)}</:col>
      </.table>

      <h2 class="text-lg font-semibold mt-6 mb-2">Recent Calls</h2>
      <.table id="recent-calls" rows={@streams.recent_calls}>
        <:col :let={{_id, call}} label="Time">{format_timestamp(call.inserted_at)}</:col>
        <:col :let={{_id, call}} label="User">{user_email(call)}</:col>
        <:col :let={{_id, call}} label="Caller">{call.caller || "—"}</:col>
        <:col :let={{_id, call}} label="Model">{call.model}</:col>
        <:col :let={{_id, call}} label="Tokens">{call.input_tokens + call.output_tokens}</:col>
        <:col :let={{_id, call}} label="Cost">{format_dollars(call.cost_cents)}</:col>
      </.table>
    </Layouts.app>
    """
  end
end
