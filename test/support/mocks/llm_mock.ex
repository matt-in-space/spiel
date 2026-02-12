defmodule Resume.LLM.Mock do
  @moduledoc """
  Mock LLM adapter for tests.
  """

  @behaviour Resume.LLM

  @impl true
  def complete(_prompt, opts \\ []) do
    system = Keyword.get(opts, :system, "")

    cond do
      String.contains?(system, "resume generation") ->
        {:ok, resume_json()}

      String.contains?(system, "career interviewer") and String.contains?(system, "opening") ->
        {:ok, ~s({"question": "Tell me about your current or most recent role."})}

      String.contains?(system, "career interviewer") ->
        {:ok,
         ~s({"facts": ["Mock extracted fact from interview"], "question": "What technologies do you work with?", "should_wrap_up": false})}

      String.contains?(system, "summarizing") ->
        {:ok,
         ~s({"recap": "You are an experienced professional with a strong background in software engineering."})}

      true ->
        {:ok, ~s(["Mock fact about career", "Mock fact about skills"])}
    end
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
      "tailoring_notes" =>
        "- Emphasized web development and Elixir/Phoenix skills\n- Highlighted microservices migration experience\n- Reordered skills to prioritize relevant technologies"
    })
  end
end
