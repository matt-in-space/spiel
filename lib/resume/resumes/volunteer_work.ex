defmodule Resume.Resumes.VolunteerWork do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.FlexDate

  @primary_key false
  embedded_schema do
    field :role, :string
    field :organization, :string
    field :description, :string

    embeds_one :start_date, FlexDate, on_replace: :update
    embeds_one :end_date, FlexDate, on_replace: :update
  end

  def changeset(volunteer_work, attrs) do
    volunteer_work
    |> cast(attrs, [:role, :organization, :description])
    |> validate_required([:role, :organization])
    |> cast_embed(:start_date)
    |> cast_embed(:end_date)
  end
end
