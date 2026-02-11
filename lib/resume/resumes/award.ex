defmodule Resume.Resumes.Award do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :title, :string
    field :issuer, :string
    field :summary, :string

    embeds_one :date, FlexDate, on_replace: :update
  end

  def changeset(award, attrs) do
    award
    |> cast(attrs, [:title, :issuer, :summary])
    |> validate_required([:title])
    |> cast_embed(:date)
  end
end
