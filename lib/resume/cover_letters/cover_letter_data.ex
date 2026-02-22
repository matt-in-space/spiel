defmodule Resume.CoverLetters.CoverLetterData do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :greeting, :string
    field :opening, :string
    field :body, {:array, :string}
    field :closing, :string
    field :signature, :string
  end

  def changeset(data, attrs) do
    data
    |> cast(attrs, [:greeting, :opening, :body, :closing, :signature])
  end
end
