defmodule Resume.Repo.Migrations.CreateResumeVersions do
  use Ecto.Migration

  def up do
    create table(:resume_versions) do
      add :resume_id, references(:resumes, on_delete: :delete_all), null: false
      add :version, :integer, null: false
      add :data, :jsonb, null: false
      add :explanation, :text
      add :trigger, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:resume_versions, [:resume_id, :version])

    execute("""
    INSERT INTO resume_versions (resume_id, version, data, explanation, trigger, inserted_at)
    SELECT id, 1, data, explanation, 'generation', inserted_at
    FROM resumes WHERE data IS NOT NULL
    """)

    alter table(:resumes) do
      remove :data, :jsonb
      remove :explanation, :text
    end
  end

  def down do
    alter table(:resumes) do
      add :data, :jsonb
      add :explanation, :text
    end

    execute("""
    UPDATE resumes SET data = rv.data, explanation = rv.explanation
    FROM (
      SELECT DISTINCT ON (resume_id) resume_id, data, explanation
      FROM resume_versions
      ORDER BY resume_id, version DESC
    ) rv
    WHERE resumes.id = rv.resume_id
    """)

    drop table(:resume_versions)
  end
end
