defmodule Resume.Feedback do
  @moduledoc """
  Processes conversational feedback on resumes.

  Takes current resume data, user context, and feedback text, then returns
  updated resume data with classification of the feedback as resume-specific,
  a lasting directive, or ambiguous.
  """

  require Logger

  alias Resume.Resumes.Generator

  @doc """
  Processes user feedback on a resume and returns updated data.

  ## Parameters

    * `resume_data` - Current resume data as a map (JSON-like)
    * `user` - The user struct with facts, directives, and default_resume_data
    * `feedback` - The feedback text from the user
    * `opts` - Options
      * `:history` - List of `%{role: :user | :assistant, content: "..."}` messages

  ## Returns

    * `{:ok, result}` where result contains:
      * `:data` - Updated resume data map
      * `:explanation` - Delta explanation of what changed
      * `:classification` - `:resume`, `:directive`, or `:ambiguous`
      * `:directive` - Directive text if classified as directive/ambiguous, nil otherwise
      * `:fact_changes` - List of fact change maps
    * `{:error, reason}`
  """
  def process_feedback(resume_data, user, feedback, opts \\ []) do
    history = Keyword.get(opts, :history, [])
    prompt = build_prompt(resume_data, user, feedback, history)

    tracking = %{user_id: user.id, caller: "feedback"}

    case Resume.LLM.tracked_complete(prompt, [system: system_prompt()], tracking) do
      {:ok, response, _usage} ->
        case parse_response(response, user) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.error("Feedback processing failed to parse LLM response: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Feedback processing LLM call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp system_prompt do
    """
    You are a resume adjustment assistant. Given a resume, user career facts, \
    standing directives, and user feedback, produce an updated resume. \
    Classify the feedback as resume-specific, a lasting directive, or ambiguous. \
    Return ONLY valid JSON, no other text.\
    """
  end

  defp build_prompt(resume_data, user, feedback, history) do
    profile = user.default_resume_data || %{}
    facts = user.facts || []
    directives = user.directives || []

    sections = [
      resume_data_section(resume_data),
      facts_section(facts),
      directives_section(directives),
      profile_section(profile),
      history_section(history),
      feedback_section(feedback),
      output_instructions()
    ]

    sections
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp resume_data_section(data) do
    """
    ## Current Resume Data
    #{Jason.encode!(data, pretty: true)}\
    """
  end

  defp facts_section([]), do: nil

  defp facts_section(facts) do
    numbered =
      facts
      |> Enum.with_index(1)
      |> Enum.map(fn {fact, i} -> "#{i}. #{fact}" end)
      |> Enum.join("\n")

    """
    ## User Career Facts
    #{numbered}\
    """
  end

  defp directives_section([]), do: nil

  defp directives_section(directives) do
    numbered =
      directives
      |> Enum.with_index(1)
      |> Enum.map(fn {d, i} -> "#{i}. #{d}" end)
      |> Enum.join("\n")

    """
    ## Standing Directives
    #{numbered}\
    """
  end

  defp profile_section(profile) when profile == %{}, do: nil

  defp profile_section(profile) do
    basic_lines =
      ["name", "email", "phone", "location", "career_goal"]
      |> Enum.map(fn key -> {key, profile[key]} end)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.map(fn {k, v} -> "- #{String.capitalize(k)}: #{v}" end)

    website_lines =
      (profile["websites"] || [])
      |> Enum.map(fn w ->
        label = website_label(w)
        "- #{label}: #{w["url"]}"
      end)

    lines = Enum.join(basic_lines ++ website_lines, "\n")

    if lines == "" do
      nil
    else
      """
      ## User Profile
      #{lines}\
      """
    end
  end

  defp website_label(%{"type" => "linkedin"}), do: "LinkedIn"
  defp website_label(%{"type" => "github"}), do: "GitHub"
  defp website_label(%{"type" => "custom", "label" => label}) when is_binary(label), do: label
  defp website_label(%{"type" => "website", "label" => label}) when is_binary(label), do: label
  defp website_label(_), do: "Website"

  defp history_section([]), do: nil

  defp history_section(history) do
    recent = Enum.take(history, -8)

    formatted =
      Enum.map(recent, fn
        %{role: role, content: content} ->
          "#{String.capitalize(to_string(role))}: #{content}"
      end)
      |> Enum.join("\n")

    """
    ## Recent Conversation
    #{formatted}\
    """
  end

  defp feedback_section(feedback) do
    """
    ## User Feedback
    #{feedback}\
    """
  end

  defp output_instructions do
    """
    ## Output Format
    Return a JSON object containing the updated resume data with these additional fields:

    #{Generator.schema_instructions()}

    Additionally, include these fields alongside the resume data:

    - "explanation": A brief description of what you changed and why (2-5 sentences)
    - "classification": One of "resume", "directive", or "ambiguous"
      - "resume" — the feedback applies only to this specific resume
      - "directive" — the feedback is a standing instruction for all future resumes (e.g. "always emphasize leadership", "never include my GPA")
      - "ambiguous" — unclear whether it's a one-time tweak or a lasting preference
    - "directive": If classification is "directive" or "ambiguous", provide the directive text as a concise standing instruction. Null otherwise.
    - "fact_changes": An array of fact corrections detected in the feedback. Each entry:
      - {"type": "add", "text": "New fact text"} — a new career fact to add
      - {"type": "update", "index": N, "text": "Updated text"} — update fact at 1-based index N
      - {"type": "remove", "index": N} — remove fact at 1-based index N
      Use an empty array if no fact changes are detected.

    Rules:
    - Apply the feedback to produce an updated version of the resume data
    - Preserve the same JSON structure as the input resume data
    - Only change what the feedback asks for — don't reorganize sections or rewrite content unnecessarily
    - The contact_info section should remain unchanged\
    """
  end

  defp parse_response(response, user) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) ->
        {explanation, data} = Map.pop(data, "explanation")
        {classification_str, data} = Map.pop(data, "classification")
        {directive, data} = Map.pop(data, "directive")
        {fact_changes, data} = Map.pop(data, "fact_changes", [])
        {_tailoring_notes, data} = Map.pop(data, "tailoring_notes")

        classification = parse_classification(classification_str)
        data = Map.put(data, "contact_info", build_contact_info(user))

        {:ok,
         %{
           data: data,
           explanation: explanation,
           classification: classification,
           directive: directive,
           fact_changes: parse_fact_changes(fact_changes)
         }}

      {:ok, _other} ->
        {:error, :invalid_format}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end

  defp parse_classification("directive"), do: :directive
  defp parse_classification("ambiguous"), do: :ambiguous
  defp parse_classification(_), do: :resume

  defp parse_fact_changes(changes) when is_list(changes) do
    Enum.filter(changes, fn
      %{"type" => type} when type in ["add", "update", "remove"] -> true
      _ -> false
    end)
  end

  defp parse_fact_changes(_), do: []

  defp build_contact_info(user) do
    profile = user.default_resume_data || %{}

    %{
      "name" => profile["name"],
      "email" => profile["email"],
      "phone" => profile["phone"],
      "location" => profile["location"],
      "websites" => profile["websites"] || []
    }
  end
end
