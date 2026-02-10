defmodule Resume.ResumesTest do
  use Resume.DataCase, async: true

  alias Resume.Resumes

  import Resume.AccountsFixtures

  describe "generate_resume/3" do
    test "creates a resume record with generated data" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, user} =
        Resume.Accounts.update_user_facts(user, [
          "Worked at Acme Corp as a Senior Software Engineer"
        ])

      {:ok, resume} = Resumes.generate_resume(user, "My Resume")

      assert resume.title == "My Resume"
      assert resume.user_id == user.id
      assert resume.data.summary != nil
      assert resume.data.contact_info.name == "Test User"
      assert length(resume.data.work_experience) > 0
    end

    test "stores job posting metadata" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, resume} =
        Resumes.generate_resume(user, "Targeted Resume",
          job_posting_text: "Senior Elixir Developer needed",
          job_posting_url: "https://example.com/jobs/123"
        )

      assert resume.job_posting_text == "Senior Elixir Developer needed"
      assert resume.job_posting_url == "https://example.com/jobs/123"
    end

    test "generated resume is persisted and retrievable" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, resume} = Resumes.generate_resume(user, "Persisted Resume")

      fetched = Resumes.get_user_resume!(user.id, resume.id)
      assert fetched.title == "Persisted Resume"
      assert fetched.data.summary != nil
    end
  end

  describe "update_resume/2" do
    test "updates the template field" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})
      {:ok, resume} = Resumes.generate_resume(user, "My Resume")

      assert resume.template == "default"
      {:ok, updated} = Resumes.update_resume(resume, %{template: "modern"})
      assert updated.template == "modern"
      assert updated.id == resume.id
    end
  end

  describe "regenerate_resume/2" do
    test "updates resume data in place" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})
      {:ok, resume} = Resumes.generate_resume(user, "My Resume")

      original_id = resume.id
      {:ok, regenerated} = Resumes.regenerate_resume(resume, user)

      assert regenerated.id == original_id
      assert regenerated.data.summary != nil
    end

    test "preserves job_posting_text context" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, resume} =
        Resumes.generate_resume(user, "Targeted", job_posting_text: "Elixir developer needed")

      {:ok, regenerated} = Resumes.regenerate_resume(resume, user)
      assert regenerated.id == resume.id
      assert regenerated.job_posting_text == "Elixir developer needed"
    end
  end
end
