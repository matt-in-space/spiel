defmodule Resume.Resumes.ContactInfo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :location, :string
    field :website, :string
    field :linkedin, :string
    field :github, :string
  end

  def changeset(contact_info, attrs) do
    contact_info
    |> cast(attrs, [:name, :email, :phone, :location, :website, :linkedin, :github])
    |> validate_required([:name])
  end
end
