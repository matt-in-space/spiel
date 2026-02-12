defmodule Resume.Resumes.GeneratorTest do
  use Resume.DataCase, async: true

  alias Resume.Resumes.Generator

  import Resume.AccountsFixtures

  describe "generate/2" do
    test "returns valid resume data map" do
      user = user_fixture()

      {:ok, user} =
        Resume.Accounts.update_user_profile(user, %{
          "name" => "Test User",
          "email" => "test@example.com",
          "location" => "San Francisco, CA"
        })

      {:ok, user} =
        Resume.Accounts.update_user_facts(user, [
          "Worked at Acme Corp as a Senior Software Engineer"
        ])

      {:ok, data, %{tailoring_notes: _, explanation: _}} = Generator.generate(user)

      assert is_map(data)
      assert is_binary(data["summary"])
      assert is_map(data["contact_info"])
      assert data["contact_info"]["name"] == "Test User"
      assert is_list(data["work_experience"])
      assert length(data["work_experience"]) > 0
      assert is_list(data["education"])
      assert is_list(data["skills"])
    end

    test "works with job posting text" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, user} =
        Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, data, %{tailoring_notes: tailoring_notes, explanation: explanation}} =
        Generator.generate(user, job_posting_text: "Looking for a senior Elixir developer")

      assert is_map(data)
      assert is_binary(data["summary"])
      assert is_binary(tailoring_notes)
      assert is_binary(explanation)
    end

    test "works with minimal user data (no facts)" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, data, %{tailoring_notes: _, explanation: _}} = Generator.generate(user)

      assert is_map(data)
    end

    test "works with directives" do
      user = user_fixture()
      {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

      {:ok, user} =
        Resume.Accounts.update_user_directives(user, [
          "Always emphasize leadership experience",
          "Keep resume to one page"
        ])

      {:ok, data, %{tailoring_notes: _, explanation: _}} = Generator.generate(user)

      assert is_map(data)
    end
  end
end
