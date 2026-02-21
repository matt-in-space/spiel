defmodule Resume.Billing do
  @moduledoc """
  Billing context — access checks, usage counting, and pass management.
  """

  import Ecto.Query

  alias Resume.Accounts.User
  alias Resume.Billing.Payment
  alias Resume.Repo

  @free_limits %{
    generation: 2,
    adjustment: 3,
    fact_update: 3
  }

  @pass_duration_days 30

  @caller_map %{
    generation: ["generator"],
    adjustment: ["feedback"],
    fact_update: ["facts", "facts_input", "interview"]
  }

  @doc """
  Checks whether the user is allowed to perform `action`.

  Returns `:ok` or `{:error, :limit_reached, message}`.
  """
  def check_allowance(%User{} = user, action) when is_atom(action) do
    cond do
      has_unlimited_access?(user) -> :ok
      has_active_pass?(user) -> :ok
      true -> check_free_limit(user, action)
    end
  end

  @doc """
  Returns true if the user has an active paid pass.
  """
  def has_active_pass?(%User{pass_expires_at: nil}), do: false

  def has_active_pass?(%User{pass_expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  @doc """
  Returns true if the user has unlimited access (admin or granted unlimited).
  """
  def has_unlimited_access?(%User{access_level: "unlimited"}), do: true
  def has_unlimited_access?(%User{role: :admin}), do: true
  def has_unlimited_access?(_), do: false

  @doc """
  Returns the number of LLM calls for the given action this calendar month.
  """
  def usage_this_month(user_id, action) do
    callers = Map.fetch!(@caller_map, action)
    month_start = beginning_of_month()

    from(c in "llm_calls",
      where: c.user_id == ^user_id,
      where: c.caller in ^callers,
      where: c.inserted_at >= ^month_start,
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Activates a 30-day pass for the user. Extends from current expiry if still active.
  """
  def activate_pass(%User{} = user) do
    base =
      if has_active_pass?(user),
        do: user.pass_expires_at,
        else: DateTime.utc_now(:second)

    expires_at = DateTime.add(base, @pass_duration_days, :day) |> DateTime.truncate(:second)

    user
    |> User.billing_changeset(%{access_level: "pass", pass_expires_at: expires_at})
    |> Repo.update()
  end

  @doc """
  Grants unlimited access to a user.
  """
  def grant_unlimited(%User{} = user) do
    user
    |> User.billing_changeset(%{access_level: "unlimited"})
    |> Repo.update()
  end

  @doc """
  Revokes unlimited access, setting the user back to free tier.
  """
  def revoke_unlimited(%User{} = user) do
    user
    |> User.billing_changeset(%{access_level: "free", pass_expires_at: nil})
    |> Repo.update()
  end

  @doc """
  Returns a usage summary map for the billing UI.
  """
  def usage_summary(%User{} = user) do
    %{
      generation: %{
        used: usage_this_month(user.id, :generation),
        limit: @free_limits.generation
      },
      adjustment: %{
        used: usage_this_month(user.id, :adjustment),
        limit: @free_limits.adjustment
      },
      fact_update: %{
        used: usage_this_month(user.id, :fact_update),
        limit: @free_limits.fact_update
      }
    }
  end

  @doc """
  Returns the current access status as a descriptive string.
  """
  def access_status(%User{} = user) do
    cond do
      has_unlimited_access?(user) and user.access_level == "unlimited" ->
        :unlimited_granted

      has_active_pass?(user) ->
        {:pass_active, user.pass_expires_at}

      true ->
        :free
    end
  end

  @doc """
  Records a payment in the ledger. Idempotent — returns existing payment if session ID exists.
  """
  def record_payment(attrs) do
    case Repo.get_by(Payment, stripe_checkout_session_id: attrs.stripe_checkout_session_id) do
      nil ->
        %Payment{}
        |> Payment.changeset(ensure_map(attrs))
        |> Repo.insert()

      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Lists recent payments for admin view.
  """
  def list_recent_payments(limit \\ 50) do
    from(p in Payment,
      order_by: [desc: p.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns aggregate payment stats for admin.
  """
  def payment_stats do
    total_revenue =
      from(p in Payment, where: p.status == "completed", select: sum(p.amount_cents))
      |> Repo.one() || 0

    paying_users =
      from(p in Payment,
        where: p.status == "completed",
        select: count(p.user_id, :distinct)
      )
      |> Repo.one()

    %{total_revenue_cents: total_revenue, paying_user_count: paying_users}
  end

  @doc """
  Searches users by email for admin billing page.
  """
  def search_users(query) do
    like = "%#{query}%"

    from(u in User, where: ilike(u.email, ^like), limit: 10)
    |> Repo.all()
  end

  # Private

  defp check_free_limit(user, action) do
    limit = Map.fetch!(@free_limits, action)
    used = usage_this_month(user.id, action)

    if used < limit do
      :ok
    else
      {:error, :limit_reached, limit_message(action, limit)}
    end
  end

  defp limit_message(:generation, limit) do
    "You've used all #{limit} free resume generations this month. Get unlimited access to keep going."
  end

  defp limit_message(:adjustment, limit) do
    "You've used all #{limit} free resume adjustments this month. Get unlimited access to keep going."
  end

  defp limit_message(:fact_update, limit) do
    "You've used all #{limit} free profile updates this month. Get unlimited access to keep going."
  end

  defp beginning_of_month do
    now = DateTime.utc_now()
    {:ok, start} = Date.new(now.year, now.month, 1)
    DateTime.new!(start, ~T[00:00:00], "Etc/UTC")
  end

  defp ensure_map(%{__struct__: _} = struct), do: Map.from_struct(struct)
  defp ensure_map(map) when is_map(map), do: map
end
