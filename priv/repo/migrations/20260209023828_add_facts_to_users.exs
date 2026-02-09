defmodule Resume.Repo.Migrations.AddFactsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :facts, :jsonb, default: "[]", null: false
    end
  end
end
