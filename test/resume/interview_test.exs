defmodule Resume.InterviewTest do
  use Resume.DataCase, async: true

  alias Resume.Interview

  describe "opening_question/2" do
    test "returns a question string with no existing facts" do
      {:ok, question} = Interview.opening_question([], %{})
      assert is_binary(question)
      assert String.length(question) > 0
    end

    test "returns a question string with existing facts" do
      facts = ["Worked at Acme Corp as a Senior Engineer"]
      profile = %{"name" => "Jane Doe", "career_goal" => "Staff engineer"}
      {:ok, question} = Interview.opening_question(facts, profile)
      assert is_binary(question)
    end
  end

  describe "process_turn/5" do
    test "returns facts, question, and should_wrap_up" do
      {:ok, result} =
        Interview.process_turn(
          "I work at Acme Corp as a senior engineer",
          [],
          [],
          1,
          %{"name" => "Jane"}
        )

      assert is_list(result.fact_operations)
      assert is_binary(result.question)
      assert is_boolean(result.should_wrap_up)
    end
  end

  describe "regenerate_career_goal/5" do
    test "returns a new career goal from instruction without existing goal" do
      {:ok, goal} =
        Interview.regenerate_career_goal(
          "I want to target DevOps roles",
          nil,
          ["5 years of backend development"],
          %{"name" => "Jane"}
        )

      assert is_binary(goal)
      assert String.length(goal) > 0
    end

    test "returns a revised career goal when existing goal is provided" do
      {:ok, goal} =
        Interview.regenerate_career_goal(
          "Focus more on cloud infrastructure",
          "Targeting senior engineering roles",
          ["5 years of backend development"],
          %{"name" => "Jane"}
        )

      assert is_binary(goal)
      assert String.length(goal) > 0
    end
  end

  describe "generate_recap/2" do
    test "returns a recap string" do
      facts = ["Worked at Acme Corp", "5 years of Elixir experience"]
      {:ok, recap} = Interview.generate_recap(facts, %{"name" => "Jane"})
      assert is_binary(recap)
      assert String.length(recap) > 0
    end
  end
end
