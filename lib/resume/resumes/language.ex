defmodule Resume.Resumes.Language do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :fluency, :string
  end

  def changeset(language, attrs) do
    language
    |> cast(attrs, [:name, :fluency])
    |> validate_required([:name])
  end
end
