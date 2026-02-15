defmodule Resume.Resumes.Resume do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.ResumeData

  schema "resumes" do
    field :title, :string
    field :template, :string, default: "default"
    field :job_posting_url, :string
    field :job_posting_text, :string
    field :explanation, :string

    embeds_one :data, ResumeData, on_replace: :update

    belongs_to :user, Resume.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(resume, attrs) do
    resume
    |> cast(attrs, [
      :title,
      :template,
      :job_posting_url,
      :job_posting_text,
      :explanation,
      :user_id
    ])
    |> validate_required([:title, :user_id])
    |> cast_embed(:data)
    |> foreign_key_constraint(:user_id)
  end
end
