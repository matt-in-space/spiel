defmodule Resume.Repo.Migrations.AddTailoringNotesToResumes do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :tailoring_notes, :text
    end
  end
end
