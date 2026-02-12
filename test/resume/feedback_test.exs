defmodule Resume.FeedbackTest do
  use Resume.DataCase, async: true

  alias Resume.Feedback

  import Resume.AccountsFixtures

  setup do
    user = user_fixture()
    {:ok, user} = Resume.Accounts.update_user_profile(user, %{"name" => "Test User"})

    {:ok, user} =
      Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

    resume_data = %{
      "summary" => "Experienced software engineer.",
      "work_experience" => [],
      "education" => [],
      "skills" => [],
      "certifications" => [],
      "projects" => [],
      "publications" => [],
      "volunteer_work" => [],
      "contact_info" => %{"name" => "Test User"}
    }

    %{user: user, resume_data: resume_data}
  end

  describe "process_feedback/4" do
    test "returns expected shape with valid classification", %{
      user: user,
      resume_data: resume_data
    } do
      {:ok, result} =
        Feedback.process_feedback(resume_data, user, "Emphasize cloud architecture")

      assert is_map(result.data)
      assert is_binary(result.explanation)
      assert result.classification in [:resume, :directive, :ambiguous]
      assert is_list(result.fact_changes)
    end

    test "returns updated resume data", %{user: user, resume_data: resume_data} do
      {:ok, result} =
        Feedback.process_feedback(resume_data, user, "Emphasize cloud architecture")

      assert is_binary(result.data["summary"])
      assert is_map(result.data["contact_info"])
      assert result.data["contact_info"]["name"] == "Test User"
    end

    test "works with conversation history", %{user: user, resume_data: resume_data} do
      history = [
        %{role: :user, content: "Add more cloud skills"},
        %{role: :assistant, content: "I've added cloud architecture emphasis."}
      ]

      {:ok, result} =
        Feedback.process_feedback(resume_data, user, "Also add AWS", history: history)

      assert is_map(result.data)
      assert is_binary(result.explanation)
    end
  end
end
