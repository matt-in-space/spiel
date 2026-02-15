defmodule Resume.Repo.Migrations.CreateLlmCalls do
  use Ecto.Migration

  def change do
    create table(:llm_calls) do
      add :user_id, references(:users, on_delete: :nilify_all), null: true
      add :caller, :string
      add :model, :string, null: false
      add :input_tokens, :integer, default: 0, null: false
      add :output_tokens, :integer, default: 0, null: false
      add :cache_creation_input_tokens, :integer, default: 0, null: false
      add :cache_read_input_tokens, :integer, default: 0, null: false
      add :cost_cents, :float, default: 0.0, null: false
      add :duration_ms, :integer, default: 0, null: false

      timestamps(updated_at: false)
    end

    create index(:llm_calls, [:user_id])
    create index(:llm_calls, [:inserted_at])
  end
end
