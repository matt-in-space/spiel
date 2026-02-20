defmodule ResumeWeb.BillingLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Billing}

  @impl true
  def mount(params, session, socket) do
    user = get_user(socket, session)
    status = Billing.access_status(user)
    usage = Billing.usage_summary(user)
    success = params["success"] == "true"

    {:ok,
     assign(socket,
       user: user,
       status: status,
       usage: usage,
       success: success,
       creating_session: false,
       page_title: "Billing"
     )}
  end

  defp get_user(socket, session) do
    case socket.assigns[:current_scope] do
      %{user: user} when not is_nil(user) ->
        user

      _ ->
        token = session["user_token"]
        {user, _inserted_at} = Accounts.get_user_by_session_token(token)
        user
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: "Billing"}]}>
      <div class="max-w-lg mx-auto space-y-6">
        <h1 class="text-2xl font-semibold tracking-tight">Billing</h1>

        <div :if={@success} class="alert alert-success">
          <.icon name="hero-check-circle-micro" class="size-5" />
          <span>Payment successful! Your unlimited access is now active.</span>
        </div>

        <div class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <h2 class="card-title text-lg">Current Plan</h2>
            <div :if={@status == :free}>
              <p class="text-sm">Free tier</p>
              <p class="text-xs opacity-70 mt-1">
                Limited monthly usage — upgrade for unlimited access.
              </p>
            </div>
            <div :if={match?({:pass_active, _}, @status)}>
              <p class="text-sm">
                Unlimited access until {format_date(elem(@status, 1))}
              </p>
            </div>
            <div :if={@status == :unlimited_granted}>
              <p class="text-sm">Unlimited access (granted)</p>
            </div>
          </div>
        </div>

        <div :if={@status == :free} class="card bg-base-200 border border-base-300">
          <div class="card-body">
            <h2 class="card-title text-lg">Usage This Month</h2>
            <div class="space-y-3 mt-2">
              <.usage_meter
                label="Resume generations"
                used={@usage.generation.used}
                limit={@usage.generation.limit}
              />
              <.usage_meter
                label="Resume adjustments"
                used={@usage.adjustment.used}
                limit={@usage.adjustment.limit}
              />
              <.usage_meter
                label="Profile updates"
                used={@usage.fact_update.used}
                limit={@usage.fact_update.limit}
              />
            </div>
          </div>
        </div>

        <div :if={@status != :unlimited_granted} class="card bg-base-200 border border-base-300">
          <div class="card-body text-center">
            <h2 class="card-title justify-center text-lg">
              {if match?({:pass_active, _}, @status),
                do: "Extend by 30 days",
                else: "Get 30-day unlimited access"}
            </h2>
            <p class="text-3xl font-bold my-2">$5</p>
            <p class="text-sm opacity-70 mb-4">One-time payment. No subscription. No auto-renewal.</p>
            <button
              phx-click="checkout"
              disabled={@creating_session}
              class="btn btn-primary"
            >
              <span :if={@creating_session} class="loading loading-spinner loading-sm"></span>
              <span :if={!@creating_session}>
                <.icon name="hero-credit-card-micro" class="size-4" />
                {if match?({:pass_active, _}, @status),
                  do: "Extend — $5",
                  else: "Get Unlimited Access — $5"}
              </span>
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp usage_meter(assigns) do
    pct = if assigns.limit > 0, do: min(assigns.used / assigns.limit * 100, 100), else: 0

    assigns = assign(assigns, :pct, pct)

    ~H"""
    <div>
      <div class="flex justify-between text-sm mb-1">
        <span>{@label}</span>
        <span class="font-medium">{@used}/{@limit}</span>
      </div>
      <progress class="progress progress-primary w-full" value={@pct} max="100"></progress>
    </div>
    """
  end

  @impl true
  def handle_event("checkout", _params, socket) do
    user = socket.assigns.user
    base_url = ResumeWeb.Endpoint.url()
    success_url = "#{base_url}/billing?success=true"
    cancel_url = "#{base_url}/billing"

    socket = assign(socket, creating_session: true)

    case Resume.Billing.Stripe.create_checkout_session(user, success_url, cancel_url) do
      {:ok, url} ->
        {:noreply, redirect(socket, external: url)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(creating_session: false)
         |> put_flash(:error, "Failed to start checkout. Please try again.")}
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end
end
