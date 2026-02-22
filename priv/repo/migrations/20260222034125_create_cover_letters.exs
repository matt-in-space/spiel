defmodule Resume.Repo.Migrations.CreateCoverLetters do
  use Ecto.Migration

  def change do
    create table(:cover_letters) do
      add :resume_id, references(:resumes, on_delete: :delete_all), null: false
      add :template, :string, default: "formal", null: false
      add :content, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cover_letters, [:resume_id])
  end
end
