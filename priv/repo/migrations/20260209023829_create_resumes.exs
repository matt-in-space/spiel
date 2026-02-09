defmodule Resume.Repo.Migrations.CreateResumes do
  use Ecto.Migration

  def change do
    create table(:resumes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :data, :jsonb
      add :template, :string, null: false, default: "default"
      add :job_posting_url, :string
      add :job_posting_text, :text

      timestamps(type: :utc_datetime)
    end

    create index(:resumes, [:user_id])
  end
end
