defmodule Resume.ResumesTest do
  use Resume.DataCase, async: true

  alias Resume.Resumes

  import Resume.AccountsFixtures

  describe "generate_resume/3" do
    test "creates a resume record with version 1" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, user} =
        Resume.Accounts.update_user_facts(user, [
          "Worked at Acme Corp as a Senior Software Engineer"
        ])

      {:ok, resume} = Resumes.generate_resume(user, "My Resume")

      assert resume.title == "My Resume"
      assert resume.user_id == user.id

      version = Resumes.get_latest_version!(resume.id)
      assert version.version == 1
      assert version.trigger == "generation"
      assert version.data != nil

      data = Resumes.dump_version_data(version)
      assert data.summary != nil
      assert data.contact_info.name == "Test User"
      assert length(data.work_experience) > 0
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

      version = Resumes.get_latest_version!(fetched.id)
      data = Resumes.dump_version_data(version)
      assert data.summary != nil
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
    test "creates a new version with trigger regeneration" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})
      {:ok, resume} = Resumes.generate_resume(user, "My Resume")

      {:ok, version} = Resumes.regenerate_resume(resume, user)

      assert version.version == 2
      assert version.trigger == "regeneration"
      assert version.data != nil
    end

    test "preserves job_posting_text context" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, resume} =
        Resumes.generate_resume(user, "Targeted", job_posting_text: "Elixir developer needed")

      {:ok, version} = Resumes.regenerate_resume(resume, user)
      assert version.version == 2
      assert resume.job_posting_text == "Elixir developer needed"
    end
  end

  describe "versions" do
    setup do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})
      {:ok, resume} = Resumes.generate_resume(user, "My Resume")
      %{user: user, resume: resume}
    end

    test "list_versions returns versions newest first", %{resume: resume} do
      versions = Resumes.list_versions(resume.id)
      assert length(versions) == 1
      assert hd(versions).version == 1
    end

    test "get_version! returns specific version", %{resume: resume} do
      version = Resumes.get_version!(resume.id, 1)
      assert version.version == 1
      assert version.trigger == "generation"
    end

    test "get_latest_version! returns the most recent version", %{resume: resume} do
      version = Resumes.get_latest_version!(resume.id)
      assert version.version == 1
    end

    test "confirm_feedback_changes creates a new version", %{resume: resume} do
      data = %{"summary" => "Updated summary"}
      {:ok, version} = Resumes.confirm_feedback_changes(resume, data, "Feedback explanation")

      assert version.version == 2
      assert version.trigger == "feedback"
      assert version.explanation == "Feedback explanation"
      assert version.data["summary"] == "Updated summary"
    end

    test "version numbering increments correctly", %{resume: resume} do
      {:ok, v2} = Resumes.create_version(resume, "feedback", %{"summary" => "v2"})
      {:ok, v3} = Resumes.create_version(resume, "feedback", %{"summary" => "v3"})

      assert v2.version == 2
      assert v3.version == 3

      versions = Resumes.list_versions(resume.id)
      assert length(versions) == 3
      assert Enum.map(versions, & &1.version) == [3, 2, 1]
    end

    test "dump_version_data converts map to ResumeData struct", %{resume: resume} do
      version = Resumes.get_latest_version!(resume.id)
      data = Resumes.dump_version_data(version)
      assert %Resume.Resumes.ResumeData{} = data
    end
  end
end
