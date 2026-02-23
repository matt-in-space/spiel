defmodule Resume.Repo.Migrations.AddDefaultTemplatesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :default_resume_template, :string, default: "default", null: false
      add :default_cover_letter_template, :string, default: "formal", null: false
    end
  end
end
