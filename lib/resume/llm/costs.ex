defmodule Resume.LLM.Costs do
  @moduledoc """
  Query helpers for LLM call costs.

  Designed for IEx use: `Resume.LLM.Costs.global_total_cents()`
  """

  import Ecto.Query

  alias Resume.LLM.Call
  alias Resume.Repo

  @doc """
  Total cost in cents for a user.
  """
  def total_cost_cents(user_id) do
    Call
    |> where(user_id: ^user_id)
    |> select([c], coalesce(sum(c.cost_cents), 0.0))
    |> Repo.one()
  end

  @doc """
  Total cost in cents for a user since a given datetime.
  """
  def total_cost_cents_since(user_id, %DateTime{} = since) do
    Call
    |> where([c], c.user_id == ^user_id and c.inserted_at >= ^since)
    |> select([c], coalesce(sum(c.cost_cents), 0.0))
    |> Repo.one()
  end

  @doc """
  Total cost in cents across all users.
  """
  def global_total_cents do
    Call
    |> select([c], coalesce(sum(c.cost_cents), 0.0))
    |> Repo.one()
  end

  @doc """
  Most recent N calls for a user.
  """
  def recent_calls(user_id, limit \\ 10) do
    Call
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Daily cost breakdown for a user over the last N days.

  Returns a list of `%{date: Date.t(), cost_cents: float(), call_count: integer()}`.
  """
  def daily_breakdown(user_id, days \\ 30) do
    since = DateTime.utc_now() |> DateTime.add(-days, :day)

    Call
    |> where([c], c.user_id == ^user_id and c.inserted_at >= ^since)
    |> group_by([c], fragment("date(?)", c.inserted_at))
    |> select([c], %{
      date: fragment("date(?)", c.inserted_at),
      cost_cents: sum(c.cost_cents),
      call_count: count(c.id)
    })
    |> order_by([c], fragment("date(?)", c.inserted_at))
    |> Repo.all()
  end

  ## Admin / global queries

  @doc """
  Total cost in cents across all users since a given datetime.
  """
  def global_total_cents_since(%DateTime{} = since) do
    Call
    |> where([c], c.inserted_at >= ^since)
    |> select([c], coalesce(sum(c.cost_cents), 0.0))
    |> Repo.one()
  end

  @doc """
  Total call count, optionally since a datetime.
  """
  def global_call_count(since \\ nil) do
    Call
    |> maybe_since(since)
    |> select([c], count(c.id))
    |> Repo.one()
  end

  @doc """
  Most recent N calls across all users, preloads `:user`.
  """
  def global_recent_calls(limit \\ 50) do
    Call
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Per-user cost breakdown. Returns list of maps with user_id, email, total_cost_cents, call_count.
  """
  def user_cost_breakdown(since \\ nil) do
    Call
    |> join(:inner, [c], u in assoc(c, :user))
    |> maybe_since(since)
    |> group_by([c, u], [u.id, u.email])
    |> select([c, u], %{
      user_id: u.id,
      email: u.email,
      total_cost_cents: sum(c.cost_cents),
      call_count: count(c.id)
    })
    |> order_by([c, u], desc: sum(c.cost_cents))
    |> Repo.all()
  end

  @doc """
  Call count and cost grouped by caller type.
  """
  def caller_breakdown(since \\ nil) do
    Call
    |> maybe_since(since)
    |> group_by([c], c.caller)
    |> select([c], %{
      caller: c.caller,
      call_count: count(c.id),
      total_cost_cents: sum(c.cost_cents)
    })
    |> order_by([c], desc: sum(c.cost_cents))
    |> Repo.all()
  end

  defp maybe_since(query, nil), do: query
  defp maybe_since(query, %DateTime{} = since), do: where(query, [c], c.inserted_at >= ^since)
end
