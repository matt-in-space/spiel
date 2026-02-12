defmodule Resume.Repo.Migrations.AddExplanationToResumes do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :explanation, :text
    end
  end
end
