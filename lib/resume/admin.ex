defmodule Resume.Admin do
  @moduledoc """
  Admin-level aggregate queries for the dashboard.
  """

  import Ecto.Query

  alias Resume.Repo
  alias Resume.Accounts.User
  alias Resume.Resumes.{Resume, Version}

  @doc """
  Returns a map of aggregate platform stats for the admin dashboard.
  """
  def dashboard_stats do
    %{
      total_users: Repo.aggregate(User, :count),
      total_resumes: Repo.aggregate(Resume, :count),
      total_versions: Repo.aggregate(Version, :count),
      most_popular_template: most_popular_template(),
      total_downloads: total_downloads()
    }
  end

  defp most_popular_template do
    Resume
    |> group_by([r], r.template)
    |> select([r], {r.template, count(r.id)})
    |> order_by([r], desc: count(r.id))
    |> limit(1)
    |> Repo.one()
    |> case do
      {template, count} -> %{template: template, count: count}
      nil -> nil
    end
  end

  defp total_downloads do
    Repo.one(from r in Resume, select: coalesce(sum(r.download_count), 0))
  end
end
