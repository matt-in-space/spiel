defmodule Resume.Interview do
  @moduledoc """
  AI-driven career interview for onboarding.

  Three functions, each a single LLM call:
  - `opening_question/2` — generates the first interview question
  - `process_turn/5` — extracts facts from a response and generates the next question
  - `generate_recap/2` — summarizes all known facts in natural language
  """

  @doc """
  Generates the opening interview question based on existing facts and profile.

  Returns `{:ok, question_string}` or `{:error, reason}`.
  """
  def opening_question(existing_facts, profile) do
    prompt = """
    #{profile_context(profile)}
    #{existing_facts_context(existing_facts)}

    Generate your opening question to start the career interview.
    If the candidate has existing facts, ask about gaps or areas that need more detail.
    If they have no facts, ask about their current or most recent role.

    Return ONLY a JSON object: {"question": "your question here"}
    """

    case Resume.LLM.complete(prompt, system: opening_system_prompt()) do
      {:ok, response} -> parse_question(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Processes a user's response: extracts new facts and generates the next question.

  Returns `{:ok, %{facts: [...], question: "...", should_wrap_up: bool}}` or `{:error, reason}`.
  """
  def process_turn(user_response, history, all_facts, turn_number, profile) do
    recent_history = Enum.take(history, -6)

    prompt = """
    #{profile_context(profile)}

    ## All Accumulated Facts
    #{format_facts(all_facts)}

    ## Recent Conversation
    #{format_history(recent_history)}

    ## Latest Response (Turn #{turn_number})
    Candidate: #{user_response}

    Extract any NEW career facts from the latest response and generate the next interview question.
    Each fact should be specific, anchored to a company/role, and include details like dates, technologies, and impact.
    Do not duplicate facts already in the accumulated list.

    If the candidate says they're done, has nothing more to add, or we're at turn #{turn_number} of ~10, set should_wrap_up to true.

    Return ONLY a JSON object:
    {"facts": ["fact 1", "fact 2"], "question": "next question", "should_wrap_up": false}
    """

    case Resume.LLM.complete(prompt, system: turn_system_prompt()) do
      {:ok, response} -> parse_turn(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates a natural-language recap of all known facts.

  Returns `{:ok, recap_string}` or `{:error, reason}`.
  """
  def generate_recap(facts, profile) do
    prompt = """
    #{profile_context(profile)}

    ## Career Facts
    #{format_facts(facts)}

    Write a concise, natural-language summary of this person's career based on the facts above.
    Organize by themes (current role, experience, skills, education) rather than listing facts verbatim.
    Keep it to 2-4 paragraphs.

    Return ONLY a JSON object: {"recap": "your summary here"}
    """

    case Resume.LLM.complete(prompt, system: recap_system_prompt()) do
      {:ok, response} -> parse_recap(response)
      {:error, reason} -> {:error, reason}
    end
  end

  # System prompts

  defp opening_system_prompt do
    "You are a career interviewer conducting an opening interview to gather career facts for a resume. Be conversational and encouraging. Return only valid JSON."
  end

  defp turn_system_prompt do
    "You are a career interviewer extracting facts and asking follow-up questions. Be conversational. Return only valid JSON."
  end

  defp recap_system_prompt do
    "You are summarizing a candidate's career facts into a natural-language overview. Return only valid JSON."
  end

  # Prompt helpers

  defp profile_context(profile) when profile == %{} or is_nil(profile), do: ""

  defp profile_context(profile) do
    lines =
      ["name", "email", "location", "career_goal"]
      |> Enum.map(fn key -> {key, profile[key] || profile[String.to_atom(key)]} end)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.map(fn {k, v} -> "- #{String.capitalize(k)}: #{v}" end)
      |> Enum.join("\n")

    if lines == "", do: "", else: "## Candidate Profile\n#{lines}"
  end

  defp existing_facts_context([]), do: "The candidate has no existing facts yet."

  defp existing_facts_context(facts) do
    "## Existing Facts\n#{format_facts(facts)}"
  end

  defp format_facts([]), do: "(none)"

  defp format_facts(facts) do
    facts
    |> Enum.with_index(1)
    |> Enum.map(fn {fact, i} -> "#{i}. #{fact}" end)
    |> Enum.join("\n")
  end

  defp format_history([]), do: "(no previous messages)"

  defp format_history(history) do
    history
    |> Enum.map(fn
      %{role: role, content: content} -> "#{String.capitalize(to_string(role))}: #{content}"
      {role, content} -> "#{String.capitalize(to_string(role))}: #{content}"
    end)
    |> Enum.join("\n")
  end

  # Parsers

  defp parse_question(response) do
    with {:ok, data} <- decode_json(response),
         question when is_binary(question) <- data["question"] do
      {:ok, question}
    else
      _ -> {:error, :invalid_response}
    end
  end

  defp parse_turn(response) do
    with {:ok, data} <- decode_json(response),
         facts when is_list(facts) <- data["facts"],
         question when is_binary(question) <- data["question"] do
      {:ok,
       %{
         facts: Enum.filter(facts, &is_binary/1),
         question: question,
         should_wrap_up: data["should_wrap_up"] == true
       }}
    else
      _ -> {:error, :invalid_response}
    end
  end

  defp parse_recap(response) do
    with {:ok, data} <- decode_json(response),
         recap when is_binary(recap) <- data["recap"] do
      {:ok, recap}
    else
      _ -> {:error, :invalid_response}
    end
  end

  defp decode_json(response) do
    cleaned =
      response
      |> String.replace(~r/```\w*\n?/, "")
      |> String.trim()

    Jason.decode(cleaned)
  end
end
