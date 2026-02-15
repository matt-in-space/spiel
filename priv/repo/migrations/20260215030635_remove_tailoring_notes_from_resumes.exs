defmodule Resume.Repo.Migrations.RemoveTailoringNotesFromResumes do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      remove :tailoring_notes, :text
    end
  end
end
