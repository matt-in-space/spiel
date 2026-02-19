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
  def opening_question(existing_facts, profile, opts \\ []) do
    prompt = """
    #{profile_context(profile)}
    #{existing_facts_context(existing_facts)}

    Generate your opening question to start the career interview.
    If the candidate has existing facts, ask about gaps or areas that need more detail.
    If they have no facts, ask what they do now or what kind of work they're looking for.
    The candidate may be experienced, a student, a career changer, or entering the workforce for the first time.

    Return ONLY a JSON object: {"question": "your question here"}
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "interview"}

    case Resume.LLM.tracked_complete(prompt, [system: opening_system_prompt()], tracking) do
      {:ok, response, _usage} -> parse_question(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Processes a user's response: extracts new facts and generates the next question.

  Returns `{:ok, %{facts: [...], question: "...", should_wrap_up: bool}}` or `{:error, reason}`.
  """
  def process_turn(user_response, history, all_facts, turn_number, profile, opts \\ []) do
    recent_history = Enum.take(history, -6)

    prompt = """
    #{profile_context(profile)}

    ## All Accumulated Facts
    #{format_facts(all_facts)}

    ## Recent Conversation
    #{format_history(recent_history)}

    ## Latest Response (Turn #{turn_number})
    Candidate: #{user_response}

    Extract career facts from the latest response and generate the next interview question.
    Each fact should be specific and include details like dates, technologies, and impact when available.
    Facts can come from work experience, education, projects, volunteer work, or goals and interests — not just employment.

    If new information refines or extends an existing fact, emit an "update" operation referencing that fact's number instead of adding a duplicate. Only emit "add" for genuinely new facts.

    If the candidate says they're done, has nothing more to add, or we're at turn #{turn_number} of ~10, set should_wrap_up to true.

    Also extract the candidate's career goal if one emerges from the conversation (e.g. what role they're
    targeting, what kind of work they want). Return it as a string, or null if none is apparent yet.

    Return ONLY a JSON object:
    {"fact_operations": [{"type": "add", "text": "..."}, {"type": "update", "index": N, "text": "..."}], "question": "next question", "should_wrap_up": false, "career_goal": "...or null"}
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "interview"}

    case Resume.LLM.tracked_complete(prompt, [system: turn_system_prompt()], tracking) do
      {:ok, response, _usage} -> parse_turn(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates a natural-language recap of all known facts.

  Returns `{:ok, recap_string}` or `{:error, reason}`.
  """
  def generate_recap(facts, profile, opts \\ []) do
    prompt = """
    #{profile_context(profile)}

    ## Career Facts
    #{format_facts(facts)}

    Write a concise, natural-language summary of this person's career based on the facts above.
    Organize by themes (current role, experience, skills, education) rather than listing facts verbatim.
    Keep it to 2-4 paragraphs.

    Return ONLY a JSON object: {"recap": "your summary here"}
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "interview"}

    case Resume.LLM.tracked_complete(prompt, [system: recap_system_prompt()], tracking) do
      {:ok, response, _usage} -> parse_recap(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Regenerates a career goal from a natural language instruction.

  Takes the user's instruction, the existing goal (or nil), their facts,
  profile data, and opts. Returns `{:ok, new_goal_string}` or `{:error, reason}`.
  """
  def regenerate_career_goal(instruction, existing_goal, facts, profile, opts \\ []) do
    prompt = """
    #{profile_context(profile)}

    ## Career Facts
    #{format_facts(facts)}

    #{existing_goal_section(existing_goal)}

    ## User Instruction
    #{instruction}

    Based on the user's instruction and their career facts, write a concise career goal statement
    (1-3 sentences). If an existing goal is provided, revise it according to the instruction.
    If no existing goal, create one from scratch.

    Return ONLY a JSON object: {"career_goal": "the career goal statement"}
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "interview"}

    case Resume.LLM.tracked_complete(prompt, [system: career_goal_system_prompt()], tracking) do
      {:ok, response, _usage} -> parse_career_goal(response)
      {:error, reason} -> {:error, reason}
    end
  end

  # System prompts

  defp career_goal_system_prompt do
    "You are a career advisor helping refine a candidate's career goal statement. Return only valid JSON."
  end

  defp opening_system_prompt do
    "You are a friendly interviewer gathering facts for a resume. The candidate may be experienced or just starting out — they could be a student, career changer, or entering the workforce for the first time. Facts include work history, education, projects, skills, volunteer work, and goals. Be conversational and encouraging. Return only valid JSON."
  end

  defp turn_system_prompt do
    "You are a friendly interviewer extracting facts and asking follow-up questions. The candidate may be experienced or just starting out. Facts include work history, education, projects, skills, volunteer work, and goals — not just employment. Be conversational and encouraging. Return only valid JSON."
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

  defp existing_goal_section(nil), do: ""
  defp existing_goal_section(""), do: ""

  defp existing_goal_section(goal) do
    "## Current Career Goal\n#{goal}"
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
         question when is_binary(question) <- data["question"] do
      career_goal =
        case data["career_goal"] do
          g when is_binary(g) and g != "" -> g
          _ -> nil
        end

      # Support both new "fact_operations" and legacy "facts" formats
      operations =
        cond do
          is_list(data["fact_operations"]) ->
            data["fact_operations"]
            |> Enum.filter(&is_map/1)

          is_list(data["facts"]) ->
            # Legacy flat array — convert to add operations
            data["facts"]
            |> Enum.filter(&is_binary/1)
            |> Enum.map(&%{"type" => "add", "text" => &1})

          true ->
            []
        end

      {:ok,
       %{
         fact_operations: operations,
         question: question,
         should_wrap_up: data["should_wrap_up"] == true,
         career_goal: career_goal
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

  defp parse_career_goal(response) do
    with {:ok, data} <- decode_json(response),
         goal when is_binary(goal) <- data["career_goal"] do
      {:ok, goal}
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
