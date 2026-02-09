defmodule Resume.Resumes.WorkExperience do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :role, :string
    field :company, :string
    field :current, :boolean, default: false
    field :accomplishments, {:array, :string}, default: []

    embeds_one :start_date, FlexDate, on_replace: :update
    embeds_one :end_date, FlexDate, on_replace: :update
  end

  def changeset(work_experience, attrs) do
    work_experience
    |> cast(attrs, [:role, :company, :current, :accomplishments])
    |> validate_required([:role, :company])
    |> cast_embed(:start_date)
    |> cast_embed(:end_date)
  end
end
