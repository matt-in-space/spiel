defmodule Resume.Repo.Migrations.AddDirectivesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :directives, {:array, :string}, default: [], null: false
    end
  end
end
