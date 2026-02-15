defmodule Resume.Resumes.Generator do
  @moduledoc """
  Generates structured resume data from user profile and facts using the LLM.
  """

  require Logger

  @doc """
  Generates resume data from a user's profile and facts.

  Returns `{:ok, resume_data_map}` or `{:error, reason}`.

  ## Options

    * `:job_posting_text` - Optional job posting text to tailor the resume to

  """
  def generate(user, opts \\ []) do
    job_posting_text = Keyword.get(opts, :job_posting_text)
    prompt = build_prompt(user, job_posting_text)

    tracking = %{user_id: user.id, caller: "generator"}

    case Resume.LLM.tracked_complete(prompt, [system: system_prompt()], tracking) do
      {:ok, response, _usage} ->
        case parse_response(response) do
          {:ok, data} ->
            {explanation, data} = Map.pop(data, "explanation")
            {_, data} = Map.pop(data, "tailoring_notes")

            {:ok, Map.put(data, "contact_info", build_contact_info(user)),
             %{explanation: explanation}}

          {:error, reason} ->
            Logger.error("Resume generation failed to parse LLM response: #{inspect(reason)}")
            Logger.debug("Raw LLM response:\n#{response}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Resume generation LLM call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_contact_info(user) do
    profile = user.default_resume_data || %{}

    %{
      "name" => profile["name"],
      "email" => profile["email"],
      "phone" => profile["phone"],
      "location" => profile["location"],
      "website" => profile["website"],
      "linkedin" => profile["linkedin"],
      "github" => profile["github"]
    }
  end

  defp system_prompt do
    """
    You are a resume generation assistant. Given career facts and profile information, \
    produce a structured resume as a JSON object. Return ONLY valid JSON, no other text.\
    """
  end

  defp build_prompt(user, job_posting_text) do
    profile = user.default_resume_data || %{}
    facts = user.facts || []
    directives = user.directives || []

    sections = [
      profile_section(profile),
      facts_section(facts),
      directives_section(directives),
      job_posting_section(job_posting_text),
      schema_instructions()
    ]

    sections
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp profile_section(profile) do
    lines =
      [
        maybe_field("Name", profile["name"]),
        maybe_field("Email", profile["email"]),
        maybe_field("Phone", profile["phone"]),
        maybe_field("Location", profile["location"]),
        maybe_field("Website", profile["website"]),
        maybe_field("LinkedIn", profile["linkedin"]),
        maybe_field("GitHub", profile["github"]),
        maybe_field("Career Goal", profile["career_goal"])
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    """
    ## Profile Information
    #{lines}\
    """
  end

  defp maybe_field(_label, nil), do: nil
  defp maybe_field(_label, ""), do: nil
  defp maybe_field(label, value), do: "- #{label}: #{value}"

  defp facts_section([]), do: nil

  defp facts_section(facts) do
    numbered =
      facts
      |> Enum.with_index(1)
      |> Enum.map(fn {fact, i} -> "#{i}. #{fact}" end)
      |> Enum.join("\n")

    """
    ## Career Facts
    #{numbered}\
    """
  end

  defp directives_section([]), do: nil

  defp directives_section(directives) do
    numbered =
      directives
      |> Enum.with_index(1)
      |> Enum.map(fn {directive, i} -> "#{i}. #{directive}" end)
      |> Enum.join("\n")

    """
    ## Directives
    Follow these instructions when generating the resume:
    #{numbered}\
    """
  end

  defp job_posting_section(nil), do: nil
  defp job_posting_section(""), do: nil

  defp job_posting_section(text) do
    """
    ## Target Job Posting
    Tailor the resume to highlight relevant experience for this position:

    #{text}\
    """
  end

  def schema_instructions do
    """
    ## Output Format
    Return a JSON object with this exact structure:

    {
      "summary": "Professional summary paragraph",
      "work_experience": [
        {
          "role": "Job Title",
          "company": "Company Name",
          "current": false,
          "start_date": {"year": 2020, "month": 1},
          "end_date": {"year": 2023, "month": 6},
          "accomplishments": ["Achievement 1", "Achievement 2"]
        }
      ],
      "education": [
        {
          "institution": "University Name",
          "degree": "Degree Type",
          "field": "Field of Study",
          "start_date": {"year": 2014, "month": 9},
          "end_date": {"year": 2018, "month": 5}
        }
      ],
      "skills": [
        {
          "category": "Category Name",
          "skills": ["Skill 1", "Skill 2"]
        }
      ],
      "certifications": [
        {
          "name": "Certification Name",
          "issuer": "Issuing Organization",
          "date": {"year": 2022, "month": 3}
        }
      ],
      "projects": [
        {
          "name": "Project Name",
          "description": "Brief description",
          "url": "https://example.com or null",
          "highlights": ["Highlight 1"]
        }
      ],
      "publications": [
        {
          "title": "Publication Title",
          "publisher": "Publisher Name",
          "url": "https://example.com or null",
          "date": {"year": 2021, "month": 6}
        }
      ],
      "volunteer_work": [
        {
          "role": "Volunteer Role",
          "organization": "Organization Name",
          "description": "Brief description",
          "start_date": {"year": 2019, "month": 1},
          "end_date": {"year": 2020, "month": 12}
        }
      ],
      "languages": [
        {
          "name": "English",
          "fluency": "Native"
        }
      ],
      "awards": [
        {
          "title": "Award Title",
          "issuer": "Issuing Organization",
          "summary": "Brief description",
          "date": {"year": 2022, "month": 3}
        }
      ]
    }

    Rules:
    - Use the career facts to fill work_experience, education, skills, and other sections
    - Write a compelling professional summary based on the career goal (if provided) and facts
    - For current positions, set "current": true and omit end_date
    - Dates should have year (required) and month (optional) — omit month if unknown
    - Omit sections that have no data (use empty arrays)
    - Each work experience accomplishment should be a concise, action-oriented bullet point
    - Group skills into logical categories
    - Include languages if mentioned (fluency: "Native", "Fluent", "Conversational", or "Basic")
    - Include awards or honors if mentioned
    - Include an "explanation" field — 2-5 sentences about what makes this resume unique: what was emphasized or tailored, and why, considering the target role or job posting (if provided) and any directives that were followed.\
    """
  end

  defp parse_response(response) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) -> {:ok, data}
      {:ok, _other} -> {:error, :invalid_format}
      {:error, _reason} -> {:error, :invalid_json}
    end
  end
end
