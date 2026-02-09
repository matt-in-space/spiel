defmodule Resume.Resumes.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :description, :string
    field :url, :string
    field :highlights, {:array, :string}, default: []
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :url, :highlights])
    |> validate_required([:name])
  end
end
