defmodule Resume.Resumes do
  @moduledoc """
  The Resumes context.
  """

  import Ecto.Query
  alias Resume.Repo
  alias Resume.Resumes.Resume

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
end
