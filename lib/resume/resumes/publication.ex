defmodule Resume.Resumes.Publication do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :title, :string
    field :publisher, :string
    field :url, :string

    embeds_one :date, FlexDate, on_replace: :update
  end

  def changeset(publication, attrs) do
    publication
    |> cast(attrs, [:title, :publisher, :url])
    |> validate_required([:title])
    |> cast_embed(:date)
  end
end
