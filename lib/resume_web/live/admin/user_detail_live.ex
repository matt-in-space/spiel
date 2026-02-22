defmodule ResumeWeb.Admin.UserDetailLive do
  use ResumeWeb, :live_view

  alias Resume.Admin
  alias Resume.LLM.Costs
  alias ResumeWeb.Layouts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    detail = Admin.get_user_detail(id)
    cost_by_caller = Admin.user_cost_by_caller(id)
    resumes = Admin.user_resumes_summary(id)
    recent_calls = Costs.recent_calls(String.to_integer(id), 20)

    {:ok,
     socket
     |> assign(
       detail: detail,
       user: detail.user,
       cost_by_caller: cost_by_caller,
       resumes: resumes,
       page_title: "Admin: #{detail.user.email}"
     )
     |> stream(:recent_calls, recent_calls)}
  end

  defp format_dollars(cents) when is_number(cents) do
    "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  end

  defp format_dollars(_), do: "$0.00"

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%Y-%m-%d")

  defp format_timestamp(dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      breadcrumbs={[
        %{label: "Admin", to: ~p"/admin"},
        %{label: "Users", to: ~p"/admin/users"},
        %{label: @user.email}
      ]}
    >
      <.header>
        {@user.email}
        <:subtitle>
          Role: {@user.role} · Access: {@user.access_level} · Pass expires: {format_date(
            @user.pass_expires_at
          )} · Joined: {format_date(@user.inserted_at)}
        </:subtitle>
      </.header>

      <div class="stats stats-vertical sm:stats-horizontal border border-base-300 w-full mb-6">
        <div class="stat">
          <div class="stat-title">Resumes</div>
          <div class="stat-value text-lg">{@detail.resume_count}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Versions</div>
          <div class="stat-value text-lg">{@detail.version_count}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Cover Letters</div>
          <div class="stat-value text-lg">{@detail.cover_letter_count}</div>
        </div>
        <div class="stat">
          <div class="stat-title">Downloads</div>
          <div class="stat-value text-lg">{@detail.total_downloads}</div>
        </div>
        <div class="stat">
          <div class="stat-title">LLM Spend</div>
          <div class="stat-value text-lg">{format_dollars(@detail.total_cost_cents)}</div>
        </div>
        <div class="stat">
          <div class="stat-title">LLM Calls</div>
          <div class="stat-value text-lg">{@detail.call_count}</div>
        </div>
      </div>

      <h2 class="text-lg font-semibold mb-2">Cost by Caller Type</h2>
      <.table id="cost-by-caller" rows={@cost_by_caller} row_id={&"caller-#{&1.caller}"}>
        <:col :let={row} label="Caller">{row.caller || "—"}</:col>
        <:col :let={row} label="Calls">{row.call_count}</:col>
        <:col :let={row} label="Total Cost">{format_dollars(row.total_cost_cents)}</:col>
      </.table>

      <h2 class="text-lg font-semibold mt-6 mb-2">Resumes</h2>
      <.table id="resumes" rows={@resumes} row_id={&"resume-#{&1.id}"}>
        <:col :let={row} label="Title">{row.title}</:col>
        <:col :let={row} label="Template">{row.template}</:col>
        <:col :let={row} label="Versions">{row.version_count}</:col>
        <:col :let={row} label="Downloads">{row.download_count}</:col>
        <:col :let={row} label="Cover Letter">{if row.has_cover_letter, do: "Yes", else: "No"}</:col>
        <:col :let={row} label="Created">{format_date(row.inserted_at)}</:col>
      </.table>

      <h2 class="text-lg font-semibold mt-6 mb-2">Recent LLM Calls</h2>
      <.table id="recent-calls" rows={@streams.recent_calls}>
        <:col :let={{_id, call}} label="Time">{format_timestamp(call.inserted_at)}</:col>
        <:col :let={{_id, call}} label="Caller">{call.caller || "—"}</:col>
        <:col :let={{_id, call}} label="Model">{call.model}</:col>
        <:col :let={{_id, call}} label="Tokens">
          {call.input_tokens + call.output_tokens}
        </:col>
        <:col :let={{_id, call}} label="Cost">{format_dollars(call.cost_cents)}</:col>
        <:col :let={{_id, call}} label="Duration">{call.duration_ms}ms</:col>
      </.table>
    </Layouts.app>
    """
  end
end
