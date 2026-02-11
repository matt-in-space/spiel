defmodule Resume.Resumes.ResumeData do
  use Ecto.Schema
  import Ecto.Changeset

  alias Resume.Resumes.{
    Award,
    ContactInfo,
    WorkExperience,
    Education,
    Language,
    SkillGroup,
    Certification,
    Project,
    Publication,
    VolunteerWork
  }

  @primary_key false
  embedded_schema do
    field :summary, :string

    embeds_one :contact_info, ContactInfo, on_replace: :update
    embeds_many :work_experience, WorkExperience, on_replace: :delete
    embeds_many :education, Education, on_replace: :delete
    embeds_many :skills, SkillGroup, on_replace: :delete
    embeds_many :certifications, Certification, on_replace: :delete
    embeds_many :projects, Project, on_replace: :delete
    embeds_many :publications, Publication, on_replace: :delete
    embeds_many :volunteer_work, VolunteerWork, on_replace: :delete
    embeds_many :languages, Language, on_replace: :delete
    embeds_many :awards, Award, on_replace: :delete
  end

  def changeset(resume_data, attrs) do
    resume_data
    |> cast(attrs, [:summary])
    |> cast_embed(:contact_info)
    |> cast_embed(:work_experience)
    |> cast_embed(:education)
    |> cast_embed(:skills)
    |> cast_embed(:certifications)
    |> cast_embed(:projects)
    |> cast_embed(:publications)
    |> cast_embed(:volunteer_work)
    |> cast_embed(:languages)
    |> cast_embed(:awards)
  end
end
