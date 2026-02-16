defmodule Resume.Resumes.ContactInfo do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.Website

  @primary_key false
  embedded_schema do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :location, :string
    embeds_many :websites, Website, on_replace: :delete
  end

  def changeset(contact_info, attrs) do
    contact_info
    |> cast(attrs, [:name, :email, :phone, :location])
    |> cast_embed(:websites)
    |> validate_required([:name])
  end
end
