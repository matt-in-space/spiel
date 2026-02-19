defmodule Resume.Repo.Migrations.ReplaceTutorialDismissedAtWithDismissedTutorials do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :tutorial_dismissed_at, :utc_datetime
      add :dismissed_tutorials, {:array, :string}, default: [], null: false
    end
  end
end
