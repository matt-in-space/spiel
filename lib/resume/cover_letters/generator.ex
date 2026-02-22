defmodule Resume.CoverLetters.Generator do
  @moduledoc """
  Generates structured cover letter data from user profile, resume data, and job posting using the LLM.
  """

  require Logger

  alias Resume.Resumes

  @doc """
  Generates cover letter content from a user's profile, resume data, and job posting.

  Returns `{:ok, content_map}` or `{:error, reason}`.
  """
  def generate(user, resume) do
    resume_data = get_resume_data(resume)
    prompt = build_prompt(user, resume, resume_data)

    tracking = %{user_id: user.id, caller: "cover_letter_generator"}

    case Resume.LLM.tracked_complete(prompt, [system: system_prompt()], tracking) do
      {:ok, response, _usage} ->
        case parse_response(response, user) do
          {:ok, content} ->
            {:ok, content}

          {:error, reason} ->
            Logger.error(
              "Cover letter generation failed to parse LLM response: #{inspect(reason)}"
            )

            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Cover letter generation LLM call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_resume_data(resume) do
    case Resumes.get_latest_version(resume.id) do
      nil -> nil
      version -> version.data
    end
  end

  defp system_prompt do
    """
    You are a cover letter writing assistant. Given career facts, profile information, \
    resume data, and a job posting, produce a structured cover letter as a JSON object. \
    Return ONLY valid JSON, no other text.\
    """
  end

  defp build_prompt(user, resume, resume_data) do
    profile = user.default_resume_data || %{}
    facts = user.facts || []
    directives = user.directives || []

    sections = [
      profile_section(profile),
      facts_section(facts),
      directives_section(directives),
      resume_data_section(resume_data),
      job_posting_section(resume.job_posting_text),
      schema_instructions(profile)
    ]

    sections
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp profile_section(profile) when profile == %{}, do: nil

  defp profile_section(profile) do
    lines =
      [
        maybe_field("Name", profile["name"]),
        maybe_field("Email", profile["email"]),
        maybe_field("Phone", profile["phone"]),
        maybe_field("Location", profile["location"]),
        maybe_field("Career Goal", profile["career_goal"])
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    if lines == "", do: nil, else: "## Profile Information\n#{lines}"
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
    Follow these instructions when generating the cover letter:
    #{numbered}\
    """
  end

  defp resume_data_section(nil), do: nil

  defp resume_data_section(resume_data) do
    json = Jason.encode!(resume_data, pretty: true)

    """
    ## Resume Data
    The cover letter should be consistent with this resume:
    #{json}\
    """
  end

  defp job_posting_section(nil), do: nil
  defp job_posting_section(""), do: nil

  defp job_posting_section(text) do
    """
    ## Target Job Posting
    Tailor the cover letter to this position:

    #{text}\
    """
  end

  defp schema_instructions(profile) do
    name = profile["name"] || "the applicant"

    """
    ## Output Format
    Return a JSON object with this exact structure:

    {
      "greeting": "Dear Hiring Manager,",
      "opening": "A compelling opening paragraph that introduces the candidate and states the position they're applying for...",
      "body": [
        "A paragraph highlighting relevant experience and achievements...",
        "Another paragraph connecting skills to the job requirements..."
      ],
      "closing": "A closing paragraph expressing enthusiasm and requesting next steps...",
      "signature": "Sincerely,\\n#{name}"
    }

    Rules:
    - The greeting should be "Dear Hiring Manager," unless the job posting mentions a specific person
    - The opening paragraph should immediately grab attention and state the target position
    - The body should be 2-3 paragraphs, each focused on a different strength or qualification
    - Draw from the resume data and career facts to provide specific, concrete examples
    - The closing should express enthusiasm and include a call to action
    - The signature should use the person's name from their profile
    - Keep the tone professional but personable
    - Total length should be appropriate for a one-page cover letter (roughly 250-400 words)
    - If a job posting is provided, tailor every section to that specific role
    - If no job posting is provided, write a general-purpose cover letter highlighting key strengths\
    """
  end

  defp parse_response(response, _user) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok,
       %{"greeting" => _, "opening" => _, "body" => _, "closing" => _, "signature" => _} = data} ->
        {:ok, data}

      {:ok, _other} ->
        {:error, :invalid_format}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end
end
