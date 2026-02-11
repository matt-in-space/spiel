defmodule Resume.Resumes do
  @moduledoc """
  The Resumes context.
  """

  import Ecto.Query
  require Logger
  alias Resume.Repo
  alias Resume.Resumes.{Generator, Resume, ResumeData}

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
  Returns a changeset for the resume's embedded data.
  """
  def change_resume_data(%Resume{} = resume, data_attrs \\ %{}) do
    data = resume.data || %ResumeData{}
    ResumeData.changeset(data, data_attrs)
  end

  @doc """
  Updates just the data field of a resume.
  """
  def update_resume_data(%Resume{} = resume, data_attrs) do
    update_resume(resume, %{data: data_attrs})
  end

  @doc """
  Regenerates a resume's data in place using the LLM.

  Re-uses the resume's existing job_posting_text for context.
  """
  def regenerate_resume(%Resume{} = resume, user) do
    opts =
      if resume.job_posting_text,
        do: [job_posting_text: resume.job_posting_text],
        else: []

    case Generator.generate(user, opts) do
      {:ok, data} ->
        case update_resume(resume, %{data: data}) do
          {:ok, resume} ->
            {:ok, resume}

          {:error, changeset} ->
            Logger.error("Failed to save regenerated resume: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generates a resume using the LLM and creates a Resume record.

  ## Options

    * `:job_posting_text` - Optional job posting text to tailor the resume to
    * `:job_posting_url` - Optional URL of the job posting

  """
  def generate_resume(user, title, opts \\ []) do
    case Generator.generate(user, opts) do
      {:ok, data} ->
        case create_resume(%{
               title: title,
               user_id: user.id,
               data: data,
               job_posting_text: Keyword.get(opts, :job_posting_text),
               job_posting_url: Keyword.get(opts, :job_posting_url)
             }) do
          {:ok, resume} ->
            {:ok, resume}

          {:error, changeset} ->
            Logger.error("Failed to save generated resume: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
