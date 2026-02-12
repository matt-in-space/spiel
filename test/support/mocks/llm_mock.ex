defmodule Resume.LLM.Mock do
  @moduledoc """
  Mock LLM adapter for tests.
  """

  @behaviour Resume.LLM

  @impl true
  def complete(_prompt, opts \\ []) do
    system = Keyword.get(opts, :system, "")

    if String.contains?(system, "resume generation") do
      {:ok, resume_json()}
    else
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
