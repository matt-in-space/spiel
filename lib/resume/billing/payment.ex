defmodule Resume.Billing.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payments" do
    belongs_to :user, Resume.Accounts.User
    field :stripe_checkout_session_id, :string
    field :stripe_payment_intent_id, :string
    field :amount_cents, :integer
    field :currency, :string, default: "usd"
    field :status, :string

    timestamps(updated_at: false)
  end

  @required ~w(user_id stripe_checkout_session_id amount_cents status)a
  @optional ~w(stripe_payment_intent_id currency)a

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:stripe_checkout_session_id)
    |> foreign_key_constraint(:user_id)
  end
end
