defmodule Resume.Repo.Migrations.AddBilling do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pass_expires_at, :utc_datetime
      add :access_level, :string, default: "free", null: false
    end

    create table(:payments) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :stripe_checkout_session_id, :string, null: false
      add :stripe_payment_intent_id, :string
      add :amount_cents, :integer, null: false
      add :currency, :string, default: "usd", null: false
      add :status, :string, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:payments, [:stripe_checkout_session_id])
    create index(:payments, [:user_id])
  end
end
