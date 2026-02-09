defmodule Resume.Resumes.FlexDate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :year, :integer
    field :month, :integer
  end

  def changeset(flex_date, attrs) do
    flex_date
    |> cast(attrs, [:year, :month])
    |> validate_required([:year])
    |> validate_number(:month, greater_than_or_equal_to: 1, less_than_or_equal_to: 12)
  end
end
