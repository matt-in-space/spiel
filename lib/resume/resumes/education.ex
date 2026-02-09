defmodule Resume.Resumes.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :institution, :string
    field :degree, :string
    field :field, :string

    embeds_one :start_date, FlexDate, on_replace: :update
    embeds_one :end_date, FlexDate, on_replace: :update
  end

  def changeset(education, attrs) do
    education
    |> cast(attrs, [:institution, :degree, :field])
    |> validate_required([:institution])
    |> cast_embed(:start_date)
    |> cast_embed(:end_date)
  end
end
