defmodule Resume.LLM.Mock do
  @moduledoc """
  Mock LLM adapter for tests.
  """

  @behaviour Resume.LLM

  alias Resume.LLM.Usage

  @impl true
  def complete(_prompt, opts \\ []) do
    system = Keyword.get(opts, :system, "")

    cond do
      String.contains?(system, "resume adjustment") ->
        {:ok, feedback_json(), mock_usage()}

      String.contains?(system, "resume generation") ->
        {:ok, resume_json(), mock_usage()}

      String.contains?(system, "interviewer") and String.contains?(system, "gathering facts") ->
        {:ok,
         ~s({"question": "Tell me a bit about yourself — what do you do now, or what kind of work are you looking for?"}),
         mock_usage()}

      String.contains?(system, "interviewer") and String.contains?(system, "extracting facts") ->
        {:ok,
         ~s({"fact_operations": [{"type": "add", "text": "Mock extracted fact from interview"}], "question": "What technologies do you work with?", "should_wrap_up": false}),
         mock_usage()}

      String.contains?(system, "summarizing") ->
        {:ok,
         ~s({"recap": "You are an experienced professional with a strong background in software engineering."}),
         mock_usage()}

      String.contains?(system, "classify") ->
        {:ok,
         ~s({"fact_operations": [{"type": "add", "text": "Mock fact from profile input"}], "directive_operations": [{"type": "add", "text": "Mock directive from profile input"}]}),
         mock_usage()}

      true ->
        {:ok,
         ~s([{"type": "add", "text": "Mock fact about career"}, {"type": "add", "text": "Mock fact about skills"}]),
         mock_usage()}
    end
  end

  defp mock_usage do
    %Usage{model: "mock"}
  end

  defp feedback_json do
    Jason.encode!(%{
      "operations" => [
        %{
          "op" => "replace",
          "section" => "summary",
          "value" =>
            "Experienced software engineer with deep expertise in web development and cloud architecture."
        }
      ],
      "explanation" => "Added cloud architecture emphasis to the summary as requested.",
      "classification" => "resume",
      "directive" => nil,
      "fact_changes" => []
    })
  end

  defp resume_json do
    Jason.encode!(%{
      "summary" => "Experienced software engineer with expertise in web development.",
      "work_experience" => [
        %{
          "role" => "Senior Software Engineer",
          "company" => "Acme Corp",
          "current" => false,
          "start_date" => %{"year" => 2020, "month" => 1},
          "end_date" => %{"year" => 2023, "month" => 6},
          "accomplishments" => [
            "Led migration to microservices architecture",
            "Mentored team of 3 junior engineers"
          ]
        }
      ],
      "education" => [
        %{
          "institution" => "State University",
          "degree" => "B.S.",
          "field" => "Computer Science",
          "start_date" => %{"year" => 2014, "month" => 9},
          "end_date" => %{"year" => 2018, "month" => 5}
        }
      ],
      "skills" => [
        %{"category" => "Languages", "skills" => ["Elixir", "JavaScript"]},
        %{"category" => "Frameworks", "skills" => ["Phoenix", "React"]}
      ],
      "certifications" => [],
      "projects" => [],
      "publications" => [],
      "volunteer_work" => [],
      "explanation" =>
        "Highlighted web development expertise and leadership experience. Grouped skills by category to emphasize full-stack capabilities. Emphasized the microservices migration as a key accomplishment.",
      "tailoring_notes" =>
        "- Emphasized web development and Elixir/Phoenix skills\n- Highlighted microservices migration experience\n- Reordered skills to prioritize relevant technologies"
    })
  end
end
