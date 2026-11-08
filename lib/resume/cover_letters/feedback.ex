defmodule Resume.CoverLetters.Feedback do
  @moduledoc """
  Processes conversational feedback on cover letters.

  Simpler than resume feedback: returns full updated content rather than
  patch operations. No classification, directives, or fact changes.
  """

  require Logger

  @doc """
  Processes user feedback on a cover letter and returns updated content.

  ## Parameters

    * `content` - Current cover letter content as a map
    * `user` - The user struct
    * `feedback` - The feedback text from the user
    * `opts` - Options
      * `:history` - List of `%{role: :user | :assistant, content: "..."}` messages

  ## Returns

    * `{:ok, %{content: map, explanation: string}}` - Updated content with explanation
    * `{:error, reason}`
  """
  def process_feedback(content, user, feedback, opts \\ []) do
    history = Keyword.get(opts, :history, [])
    prompt = build_prompt(content, user, feedback, history)

    tracking = %{user_id: user.id, caller: "cover_letter_feedback"}

    case Resume.LLM.tracked_complete(prompt, [system: system_prompt()], tracking) do
      {:ok, response, _usage} ->
        case parse_response(response) do
          {:ok, result} ->
            {:ok, result}

          {:error, reason} ->
            Logger.error(
              "Cover letter feedback processing failed to parse LLM response: #{inspect(reason)}"
            )

            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Cover letter feedback LLM call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp system_prompt do
    """
    You are a cover letter editing assistant. Given the current cover letter content and user feedback, \
    produce an updated cover letter as a JSON object. Return ONLY valid JSON, no other text.\
    """
  end

  defp build_prompt(content, user, feedback, history) do
    profile = user.default_resume_data || %{}

    sections = [
      current_content_section(content),
      profile_section(profile),
      history_section(history),
      feedback_section(feedback),
      output_instructions()
    ]

    sections
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp current_content_section(content) do
    """
    ## Current Cover Letter
    #{Jason.encode!(content, pretty: true)}\
    """
  end

  defp profile_section(profile) when profile == %{}, do: nil

  defp profile_section(profile) do
    name = profile["name"]
    if name, do: "## Author\n- Name: #{name}", else: nil
  end

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
    Return a JSON object with the full updated cover letter content and an explanation:

    {
      "greeting": "Dear Hiring Manager,",
      "opening": "Updated opening paragraph...",
      "body": ["Updated body paragraph 1...", "Updated body paragraph 2..."],
      "closing": "Updated closing paragraph...",
      "signature": "Sincerely,\\nName",
      "explanation": "Brief description of what changed (1-3 sentences)"
    }

    Rules:
    - Return the COMPLETE updated cover letter, not just changed parts
    - Only modify sections that the feedback applies to
    - Keep unchanged sections exactly as they were
    - The explanation should describe what was changed and why
    - Maintain professional tone and appropriate length
    - The opening, body paragraphs, and closing support inline markers: **text** for bold, *text* for italic, ==text== for highlight. Never use HTML or other Markdown.
    - Only add, remove, or change those markers when the feedback asks for it; otherwise preserve any that already exist\
    """
  end

  defp parse_response(response) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok,
       %{"greeting" => _, "opening" => _, "body" => _, "closing" => _, "signature" => _} = data} ->
        {explanation, content} = Map.pop(data, "explanation")
        {:ok, %{content: content, explanation: explanation}}

      {:ok, _other} ->
        {:error, :invalid_format}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end
end
