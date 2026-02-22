defmodule Resume.Admin do
  @moduledoc """
  Admin-level aggregate queries for the dashboard.
  """

  import Ecto.Query

  alias Resume.Repo
  alias Resume.Accounts.User
  alias Resume.LLM.Call
  alias Resume.CoverLetters.CoverLetter
  alias Resume.Resumes.{Resume, Version}

  @per_page 20

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

  @doc """
  Returns a paginated list of users, optionally filtered by email search.

  Options:
    * `:search` — email substring filter (ilike)
    * `:page` — page number (default 1)
  """
  def list_users(opts \\ []) do
    search = Keyword.get(opts, :search, "")
    page = max(Keyword.get(opts, :page, 1), 1)
    offset = (page - 1) * @per_page

    base =
      User
      |> order_by(desc: :inserted_at)

    base =
      if search != "" do
        like = "%#{search}%"
        where(base, [u], ilike(u.email, ^like))
      else
        base
      end

    total = Repo.aggregate(base, :count)
    users = base |> limit(@per_page) |> offset(^offset) |> Repo.all()
    total_pages = max(ceil(total / @per_page), 1)

    # Batch-load resume counts
    user_ids = Enum.map(users, & &1.id)

    resume_counts =
      from(r in Resume,
        where: r.user_id in ^user_ids,
        group_by: r.user_id,
        select: {r.user_id, count(r.id)}
      )
      |> Repo.all()
      |> Map.new()

    users_with_counts =
      Enum.map(users, fn user ->
        %{id: user.id, user: user, resume_count: Map.get(resume_counts, user.id, 0)}
      end)

    %{users: users_with_counts, page: page, total_pages: total_pages, total: total}
  end

  @doc """
  Returns comprehensive stats for a single user.
  """
  def get_user_detail(user_id) do
    user = Repo.get!(User, user_id)

    resume_count =
      from(r in Resume, where: r.user_id == ^user_id, select: count())
      |> Repo.one()

    version_count =
      from(v in Version,
        join: r in Resume,
        on: v.resume_id == r.id,
        where: r.user_id == ^user_id,
        select: count()
      )
      |> Repo.one()

    cover_letter_count =
      from(cl in CoverLetter,
        join: r in Resume,
        on: cl.resume_id == r.id,
        where: r.user_id == ^user_id,
        select: count()
      )
      |> Repo.one()

    total_downloads =
      from(r in Resume,
        where: r.user_id == ^user_id,
        select: coalesce(sum(r.download_count), 0)
      )
      |> Repo.one()

    llm_stats =
      from(c in Call,
        where: c.user_id == ^user_id,
        select: %{
          total_cost_cents: coalesce(sum(c.cost_cents), 0.0),
          call_count: count(c.id)
        }
      )
      |> Repo.one()

    %{
      user: user,
      resume_count: resume_count,
      version_count: version_count,
      cover_letter_count: cover_letter_count,
      total_downloads: total_downloads,
      total_cost_cents: llm_stats.total_cost_cents,
      call_count: llm_stats.call_count
    }
  end

  @doc """
  Returns per-caller LLM cost breakdown for a single user.
  """
  def user_cost_by_caller(user_id) do
    from(c in Call,
      where: c.user_id == ^user_id,
      group_by: c.caller,
      select: %{
        caller: c.caller,
        call_count: count(c.id),
        total_cost_cents: sum(c.cost_cents)
      },
      order_by: [desc: sum(c.cost_cents)]
    )
    |> Repo.all()
  end

  @doc """
  Returns resume summaries for a user, including version counts and cover letter presence.
  """
  def user_resumes_summary(user_id) do
    from(r in Resume,
      where: r.user_id == ^user_id,
      left_join: v in assoc(r, :versions),
      left_join: cl in assoc(r, :cover_letter),
      group_by: [r.id, cl.id],
      select: %{
        id: r.id,
        title: r.title,
        template: r.template,
        download_count: r.download_count,
        version_count: count(v.id),
        has_cover_letter: not is_nil(cl.id),
        inserted_at: r.inserted_at
      },
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
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
