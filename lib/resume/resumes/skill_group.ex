defmodule Resume.Resumes.SkillGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :category, :string
    field :skills, {:array, :string}, default: []
  end

  def changeset(skill_group, attrs) do
    skill_group
    |> cast(attrs, [:category, :skills])
    |> validate_required([:category, :skills])
  end
end
