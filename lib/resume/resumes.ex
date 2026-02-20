defmodule Resume.Resumes do
  @moduledoc """
  The Resumes context.
  """

  import Ecto.Query
  require Logger
  alias Resume.Billing
  alias Resume.Repo
  alias Resume.Resumes.{Generator, Resume, ResumeData, Version}

  @doc """
  Returns all resumes for a given user.
  """
  def list_resumes_for_user(user_id) do
    Resume
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single resume. Raises if not found.
  """
  def get_resume!(id), do: Repo.get!(Resume, id)

  @doc """
  Gets a single resume belonging to a user. Raises if not found.
  """
  def get_user_resume!(user_id, id) do
    Resume
    |> where(user_id: ^user_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a resume.
  """
  def create_resume(attrs) do
    %Resume{}
    |> Resume.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resume.
  """
  def update_resume(%Resume{} = resume, attrs) do
    resume
    |> Resume.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resume.
  """
  def delete_resume(%Resume{} = resume) do
    Repo.delete(resume)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resume changes.
  """
  def change_resume(%Resume{} = resume, attrs \\ %{}) do
    Resume.changeset(resume, attrs)
  end

  @doc """
  Atomically increments the download count for a resume.
  """
  def increment_download_count(%Resume{id: id}) do
    from(r in Resume, where: r.id == ^id)
    |> Repo.update_all(inc: [download_count: 1])
  end

  # --- Versions ---

  @doc """
  Returns all versions for a resume, newest first.
  """
  def list_versions(resume_id) do
    Version
    |> where(resume_id: ^resume_id)
    |> order_by(desc: :version)
    |> Repo.all()
  end

  @doc """
  Gets a single version by resume_id and version number. Raises if not found.
  """
  def get_version!(resume_id, version_number) do
    Version
    |> where(resume_id: ^resume_id, version: ^version_number)
    |> Repo.one!()
  end

  @doc """
  Gets the latest version for a resume. Raises if not found.
  """
  def get_latest_version!(resume_id) do
    Version
    |> where(resume_id: ^resume_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> Repo.one!()
  end

  @doc """
  Gets the latest version for a resume. Returns nil if none exist.
  """
  def get_latest_version(resume_id) do
    Version
    |> where(resume_id: ^resume_id)
    |> order_by(desc: :version)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a new version for a resume, auto-computing the next version number.
  """
  def create_version(%Resume{} = resume, trigger, data, explanation \\ nil) do
    next_version =
      (Repo.one(
         from v in Version,
           where: v.resume_id == ^resume.id,
           select: max(v.version)
       ) || 0) + 1

    %Version{}
    |> Version.changeset(%{
      resume_id: resume.id,
      version: next_version,
      data: data,
      explanation: explanation,
      trigger: trigger
    })
    |> Repo.insert()
  end

  @doc """
  Decodes a version's JSONB data map into a ResumeData struct.
  """
  def dump_version_data(%Version{data: data}) do
    %ResumeData{}
    |> ResumeData.changeset(data)
    |> Ecto.Changeset.apply_changes()
  end

  # --- Generation ---

  @doc """
  Generates a resume using the LLM and creates a Resume record with version 1.

  ## Options

    * `:title` - Optional explicit title (otherwise LLM-generated)
    * `:job_posting_text` - Optional job posting text to tailor the resume to
    * `:job_posting_url` - Optional URL of the job posting

  """
  def generate_resume(user, opts \\ []) do
    case Billing.check_allowance(user, :generation) do
      :ok -> generate_resume_unchecked(user, opts)
      error -> error
    end
  end

  defp generate_resume_unchecked(user, opts) do
    case Generator.generate(user, opts) do
      {:ok, data, %{explanation: explanation, title: generated_title}} ->
        title = Keyword.get(opts, :title) || generated_title || fallback_title()

        Repo.transaction(fn ->
          case create_resume(%{
                 title: title,
                 user_id: user.id,
                 job_posting_text: Keyword.get(opts, :job_posting_text),
                 job_posting_url: Keyword.get(opts, :job_posting_url)
               }) do
            {:ok, resume} ->
              case create_version(resume, "generation", data, explanation) do
                {:ok, _version} -> resume
                {:error, changeset} -> Repo.rollback(changeset)
              end

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fallback_title do
    "Resume - #{Calendar.strftime(DateTime.utc_now(), "%b %d, %Y")}"
  end

  @doc """
  Regenerates a resume's data using the LLM, creating a new version.
  """
  def regenerate_resume(%Resume{} = resume, user) do
    case Billing.check_allowance(user, :generation) do
      :ok -> regenerate_resume_unchecked(resume, user)
      error -> error
    end
  end

  defp regenerate_resume_unchecked(%Resume{} = resume, user) do
    opts =
      if resume.job_posting_text,
        do: [job_posting_text: resume.job_posting_text],
        else: []

    case Generator.generate(user, opts) do
      {:ok, data, %{explanation: explanation}} ->
        create_version(resume, "regeneration", data, explanation)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Creates a new version from feedback confirmation.
  """
  def confirm_feedback_changes(%Resume{} = resume, data, explanation) do
    create_version(resume, "feedback", data, explanation)
  end

  @doc """
  Creates a new version from a direct section edit (no LLM call).
  """
  def confirm_direct_edit(%Resume{} = resume, data, section_label) do
    create_version(resume, "direct_edit", data, "Edited #{section_label}")
  end
end
