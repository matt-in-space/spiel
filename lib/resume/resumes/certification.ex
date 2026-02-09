defmodule Resume.Resumes.Certification do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :name, :string
    field :issuer, :string

    embeds_one :date, FlexDate, on_replace: :update
  end

  def changeset(certification, attrs) do
    certification
    |> cast(attrs, [:name, :issuer])
    |> validate_required([:name])
    |> cast_embed(:date)
  end
end
