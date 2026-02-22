defmodule Resume.CoverLetters.CoverLetter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cover_letters" do
    field :template, :string, default: "formal"
    field :content, :map

    belongs_to :resume, Resume.Resumes.Resume

    timestamps(type: :utc_datetime)
  end

  def changeset(cover_letter, attrs) do
    cover_letter
    |> cast(attrs, [:template, :content, :resume_id])
    |> validate_required([:resume_id])
    |> unique_constraint(:resume_id)
    |> foreign_key_constraint(:resume_id)
  end
end
