defmodule Resume.Resumes.Resume do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.Version

  schema "resumes" do
    field :title, :string
    field :template, :string, default: "default"
    field :job_posting_url, :string
    field :job_posting_text, :string
    field :download_count, :integer, default: 0

    belongs_to :user, Resume.Accounts.User
    has_many :versions, Version

    timestamps(type: :utc_datetime)
  end

  def changeset(resume, attrs) do
    resume
    |> cast(attrs, [
      :title,
      :template,
      :job_posting_url,
      :job_posting_text,
      :user_id
    ])
    |> validate_required([:title, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
