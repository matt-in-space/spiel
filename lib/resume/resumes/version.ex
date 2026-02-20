defmodule Resume.Resumes.Version do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.Resume

  @triggers ~w(generation regeneration feedback direct_edit)

  schema "resume_versions" do
    field :version, :integer
    field :data, :map
    field :explanation, :string
    field :trigger, :string

    belongs_to :resume, Resume

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:version, :data, :explanation, :trigger, :resume_id])
    |> validate_required([:version, :data, :trigger, :resume_id])
    |> validate_inclusion(:trigger, @triggers)
    |> unique_constraint([:resume_id, :version])
    |> foreign_key_constraint(:resume_id)
  end
end
