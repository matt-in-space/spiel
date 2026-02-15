defmodule Resume.Facts do
  @moduledoc """
  Shared fact extraction from text using the LLM pipeline.
  """

  @doc """
  Extracts career facts from a list of text chunks.

  The `context` parameter is a human-readable string describing the source,
  e.g. `"their current or most recent role"` or `"an uploaded document about their career"`.

  Returns `{:ok, facts}` or `{:error, reason}`.
  """
  def extract(texts, context, opts \\ []) when is_list(texts) do
    combined = Enum.join(texts, "\n\n")
    existing_facts = Keyword.get(opts, :existing_facts, [])

    prompt = """
    You are extracting career facts from text. The source is: #{context}
    #{existing_facts_section(existing_facts)}
    Text:
    #{combined}

    Extract NEW career facts from this text. These facts will later be used to build a resume, so each fact must include enough context to be placed correctly:

    1. **Anchor facts to a place and time.** Always mention the company/organization name and dates or timeframe when available. Start accomplishment facts with "At [Company]," or "While at [Company] (dates),".
    2. **Include role/title facts.** When someone's role or title at a company is mentioned, emit a dedicated fact for it, e.g. "Worked at Bonusly from 2020 to present as a Senior and then Staff Software Engineer."
    3. **Group related accomplishments.** If several details describe the same initiative (e.g. migrated tooling, cut test time, reduced CI time), combine them into one fact covering the initiative and its outcomes.
    4. **Be specific.** Include technologies, numbers, team sizes, and impact when available. Each fact should be 1-3 sentences.
    5. **Do not duplicate existing facts.** If the text repeats information already captured in the existing facts listed above, skip it. Only extract genuinely new information. If the text adds detail to an existing fact, extract only the new detail as a standalone fact.

    Return ONLY a JSON array of strings, no other text. If there are no new facts to extract, return an empty array [].

    Example output:
    [
      "Worked at Bonusly from 2020 to present, initially as a Senior Software Engineer and promoted to Staff Software Engineer in 2022.",
      "At Bonusly, led migration from Create React App to Vite with Vitest across 10 applications, cutting test execution time in half and reducing CI/CD pipeline time by 5x.",
      "At Acme Corp (2017-2020), managed a team of 5 engineers, establishing code review processes and mentoring two junior developers to promotion."
    ]
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "facts"}

    case Resume.LLM.tracked_complete(
           prompt,
           [
             system:
               "You are a career fact extraction assistant. Return only valid JSON arrays of strings. Every accomplishment fact must reference the company where it happened. Include dedicated role/tenure facts for each position mentioned."
           ],
           tracking
         ) do
      {:ok, response, _usage} -> {:ok, parse_facts(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parses an LLM response into a list of fact strings.

  Tries JSON array first, falls back to line splitting.
  """
  def parse_facts(response) do
    cleaned = strip_code_fence(response)

    case Jason.decode(cleaned) do
      {:ok, facts} when is_list(facts) ->
        Enum.filter(facts, &is_binary/1)

      _ ->
        cleaned
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 in ["", "[", "]"]))
        |> Enum.map(&String.replace(&1, ~r/^[-*•]\s*/, ""))
        |> Enum.map(&String.replace(&1, ~r/,\s*$/, ""))
        |> Enum.map(&strip_json_string_wrapper/1)
        |> Enum.reject(&(&1 == ""))
    end
  end

  defp existing_facts_section([]), do: ""

  defp existing_facts_section(facts) do
    numbered =
      facts
      |> Enum.with_index(1)
      |> Enum.map(fn {fact, i} -> "#{i}. #{fact}" end)
      |> Enum.join("\n")

    """

    ## Existing Facts (already captured — do not re-extract these)
    #{numbered}
    """
  end

  defp strip_code_fence(text) do
    text
    |> String.replace(~r/```\w*\n?/, "")
    |> String.trim()
  end

  defp strip_json_string_wrapper(line) do
    case Regex.run(~r/^\s*"(.*)"\s*$/, line) do
      [_, inner] -> inner
      _ -> line
    end
  end
end
