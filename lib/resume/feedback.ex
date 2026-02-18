defmodule Resume.Feedback do
  @moduledoc """
  Processes conversational feedback on resumes.

  Takes current resume data, user context, and feedback text, then returns
  updated resume data with classification of the feedback as resume-specific,
  a lasting directive, or ambiguous.
  """

  require Logger

  alias Resume.Feedback.Patch
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
        case parse_response(response, resume_data, user) do
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
    standing directives, and user feedback, produce change operations that update the resume. \
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
    Return a JSON object with change operations instead of the full resume. Only include operations for parts that actually change.

    ```json
    {
      "operations": [ ... ],
      "explanation": "Brief description of what changed (2-5 sentences)",
      "classification": "resume" | "directive" | "ambiguous",
      "directive": "Standing instruction text, or null",
      "fact_changes": []
    }
    ```

    ### Operation types (indices are 0-based)

    Replace a top-level scalar (e.g. summary):
      {"op": "replace", "section": "summary", "value": "New text"}

    Replace a single field within an array item:
      {"op": "replace_item", "section": "work_experience", "index": 0, "field": "role", "value": "New Title"}

    Replace an entire array item:
      {"op": "replace_item", "section": "work_experience", "index": 0, "value": { ...full item... }}

    Replace an entire array section:
      {"op": "replace_section", "section": "skills", "value": [ ...full array... ]}

    Append an item to an array:
      {"op": "add_item", "section": "certifications", "value": { ...item... }}

    Remove an item from an array:
      {"op": "remove_item", "section": "work_experience", "index": 1}

    ### Sections
    Top-level scalars: summary
    Array sections: work_experience, education, skills, certifications, projects, publications, volunteer_work, languages, awards

    #{Generator.section_field_reference()}

    ### classification values
    - "resume" — applies only to this specific resume
    - "directive" — standing instruction for all future resumes
    - "ambiguous" — unclear whether one-time or lasting

    ### fact_changes
    - {"type": "add", "text": "New fact"} — add a career fact
    - {"type": "update", "index": N, "text": "Updated text"} — update fact at 1-based index N
    - {"type": "remove", "index": N} — remove fact at 1-based index N
    Use an empty array if no fact changes.

    Rules:
    - Only include operations for what actually changes — do NOT return unchanged data
    - Do not touch the contact_info section
    - Prefer replace_item with field over replacing whole items when only one field changes\
    """
  end

  defp parse_response(response, resume_data, user) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, %{"operations" => ops} = parsed} when is_list(ops) ->
        data = Patch.apply(resume_data, ops)
        data = Map.put(data, "contact_info", build_contact_info(user))

        {:ok,
         %{
           data: data,
           explanation: parsed["explanation"],
           classification: parse_classification(parsed["classification"]),
           directive: parsed["directive"],
           fact_changes: parse_fact_changes(parsed["fact_changes"] || [])
         }}

      {:ok, data} when is_map(data) ->
        # Legacy fallback: LLM returned full resume JSON
        {explanation, data} = Map.pop(data, "explanation")
        {classification_str, data} = Map.pop(data, "classification")
        {directive, data} = Map.pop(data, "directive")
        {fact_changes, data} = Map.pop(data, "fact_changes", [])
        {_tailoring_notes, data} = Map.pop(data, "tailoring_notes")
        {_operations, data} = Map.pop(data, "operations")

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
