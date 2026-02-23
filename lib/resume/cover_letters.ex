defmodule Resume.CoverLetters do
  @moduledoc """
  The CoverLetters context.
  """

  import Ecto.Query

  alias Resume.Repo
  alias Resume.CoverLetters.{CoverLetter, CoverLetterData}

  @doc """
  Gets the cover letter for a resume. Returns nil if none exists.
  """
  def get_by_resume(resume_id) do
    CoverLetter
    |> where(resume_id: ^resume_id)
    |> Repo.one()
  end

  @doc """
  Creates a cover letter for a resume.
  """
  def create_cover_letter(resume_id, content, template \\ "formal") do
    %CoverLetter{}
    |> CoverLetter.changeset(%{
      resume_id: resume_id,
      content: content,
      template: template
    })
    |> Repo.insert()
  end

  @doc """
  Updates a cover letter's content and/or template.
  """
  def update_cover_letter(%CoverLetter{} = cover_letter, attrs) do
    cover_letter
    |> CoverLetter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cover letter.
  """
  def delete_cover_letter(%CoverLetter{} = cover_letter) do
    Repo.delete(cover_letter)
  end

  @doc """
  Generates a cover letter using the LLM.

  Requires a paid user. Creates a new cover letter or replaces existing content.
  """
  def generate_cover_letter(resume, user) do
    alias Resume.CoverLetters.Generator

    case Generator.generate(user, resume) do
      {:ok, content} ->
        case get_by_resume(resume.id) do
          nil -> create_cover_letter(resume.id, content, user.default_cover_letter_template)
          existing -> update_cover_letter(existing, %{content: content})
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Regenerates a cover letter, replacing existing content.
  """
  def regenerate_cover_letter(resume, user) do
    generate_cover_letter(resume, user)
  end

  @doc """
  Decodes a cover letter's content map into a CoverLetterData struct.
  """
  def dump_content(%CoverLetter{content: content}) when is_map(content) do
    %CoverLetterData{}
    |> CoverLetterData.changeset(content)
    |> Ecto.Changeset.apply_changes()
  end

  def dump_content(%CoverLetter{content: nil}) do
    %CoverLetterData{}
  end
end
