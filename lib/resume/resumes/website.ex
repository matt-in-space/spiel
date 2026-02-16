defmodule Resume.Resumes.Website do
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_types ~w(linkedin github website custom)

  @primary_key false
  embedded_schema do
    field :type, :string
    field :url, :string
    field :label, :string
  end

  def changeset(website, attrs) do
    website
    |> cast(attrs, [:type, :url, :label])
    |> validate_required([:type, :url])
    |> validate_inclusion(:type, @allowed_types)
  end
end
