defmodule Resume.Repo.Migrations.AddDefaultResumeDataToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_resume_data, :jsonb, null: false, default: "{}"
      add :onboarding_completed_at, :utc_datetime
    end
  end
end
