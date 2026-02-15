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
end
