defmodule Resume.Repo.Migrations.AddDownloadCountToResumes do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :download_count, :integer, default: 0, null: false
    end
  end
end
