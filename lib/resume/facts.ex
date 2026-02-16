defmodule Resume.Facts do
  @moduledoc """
  Shared fact extraction from text using the LLM pipeline.
  """

  @doc """
  Extracts career facts from a list of text chunks.

  The `context` parameter is a human-readable string describing the source,
  e.g. `"their current or most recent role"` or `"an uploaded document about their career"`.

  Returns `{:ok, operations}` where operations is a list of
  `%{"type" => "add", "text" => "..."}` or `%{"type" => "update", "index" => N, "text" => "..."}` maps.
  """
  def extract(texts, context, opts \\ []) when is_list(texts) do
    combined = Enum.join(texts, "\n\n")
    existing_facts = Keyword.get(opts, :existing_facts, [])

    prompt = """
    You are extracting career facts from text. The source is: #{context}
    #{existing_facts_section(existing_facts)}
    Text:
    #{combined}

    Extract career facts from this text. These facts will later be used to build a resume, so each fact must include enough context to be placed correctly:

    1. **Anchor facts to a place and time.** Always mention the company/organization name and dates or timeframe when available. Start accomplishment facts with "At [Company]," or "While at [Company] (dates),".
    2. **Include role/title facts.** When someone's role or title at a company is mentioned, emit a dedicated fact for it, e.g. "Worked at Bonusly from 2020 to present as a Senior and then Staff Software Engineer."
    3. **Group related accomplishments.** If several details describe the same initiative (e.g. migrated tooling, cut test time, reduced CI time), combine them into one fact covering the initiative and its outcomes.
    4. **Be specific.** Include technologies, numbers, team sizes, and impact when available. Each fact should be 1-3 sentences.
    5. **Merge with existing facts when possible.** If new information refines, extends, or corrects an existing fact, emit an "update" operation referencing that fact's number. Only emit "add" for genuinely new facts that don't overlap with any existing fact.

    Return ONLY a JSON array of operations, no other text. Each operation is one of:
    - `{"type": "add", "text": "New fact text"}` — for genuinely new facts
    - `{"type": "update", "index": N, "text": "Merged fact text"}` — to replace existing fact #N with an improved version that incorporates new details

    If there are no new facts to extract, return an empty array [].

    Example output:
    [
      {"type": "add", "text": "At Bonusly, led migration from CRA to Vite across 10 apps, cutting test time in half."},
      {"type": "update", "index": 2, "text": "Worked at Bonusly from 2020 to present as Senior then Staff Software Engineer, promoted in 2022."}
    ]
    """

    tracking = %{user_id: Keyword.get(opts, :user_id), caller: "facts"}

    case Resume.LLM.tracked_complete(
           prompt,
           [
             system:
               "You are a career fact extraction assistant. Return only valid JSON arrays of operation objects. Every accomplishment fact must reference the company where it happened. Include dedicated role/tenure facts for each position mentioned."
           ],
           tracking
         ) do
      {:ok, response, _usage} -> {:ok, parse_operations(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parses an LLM response into a list of structured operations.

  Expects a JSON array of `%{"type" => "add"|"update", ...}` maps.
  Falls back to treating a flat array of strings as all "add" operations.
  """
  def parse_operations(response) do
    cleaned = strip_code_fence(response)

    case Jason.decode(cleaned) do
      {:ok, items} when is_list(items) ->
        if Enum.all?(items, &is_binary/1) do
          # Flat array of strings — backwards compat, treat as adds
          Enum.map(items, &%{"type" => "add", "text" => &1})
        else
          items
          |> Enum.filter(&is_map/1)
          |> Enum.filter(&valid_operation?/1)
        end

      _ ->
        # Line-splitting fallback — treat each line as an add
        cleaned
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 in ["", "[", "]"]))
        |> Enum.map(&String.replace(&1, ~r/^[-*•]\s*/, ""))
        |> Enum.map(&String.replace(&1, ~r/,\s*$/, ""))
        |> Enum.map(&strip_json_string_wrapper/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&%{"type" => "add", "text" => &1})
    end
  end

  @doc """
  Applies a list of structured fact operations to an existing facts list.

  Operations: `%{"type" => "add"|"update"|"remove", ...}`

  Returns `{updated_facts, descriptions}` where descriptions is a list of
  human-readable strings explaining what changed.
  """
  def apply_changes(facts, operations) do
    Enum.reduce(operations, {facts, []}, fn op, {facts_acc, descs} ->
      case op do
        %{"type" => "add", "text" => text} when is_binary(text) ->
          {facts_acc ++ [text], descs ++ ["Added: \"#{text}\""]}

        %{"type" => "update", "index" => idx, "text" => text}
        when is_integer(idx) and is_binary(text) ->
          zero_idx = idx - 1

          if zero_idx >= 0 and zero_idx < length(facts_acc) do
            {List.replace_at(facts_acc, zero_idx, text),
             descs ++ ["Updated ##{idx}: \"#{text}\""]}
          else
            {facts_acc, descs}
          end

        %{"type" => "remove", "index" => idx} when is_integer(idx) ->
          zero_idx = idx - 1

          if zero_idx >= 0 and zero_idx < length(facts_acc) do
            {List.delete_at(facts_acc, zero_idx), descs ++ ["Removed ##{idx}"]}
          else
            {facts_acc, descs}
          end

        _ ->
          {facts_acc, descs}
      end
    end)
  end

  defp valid_operation?(%{"type" => "add", "text" => t}) when is_binary(t), do: true

  defp valid_operation?(%{"type" => "update", "index" => i, "text" => t})
       when is_integer(i) and is_binary(t), do: true

  defp valid_operation?(%{"type" => "remove", "index" => i}) when is_integer(i), do: true
  defp valid_operation?(_), do: false

  defp existing_facts_section([]), do: ""

  defp existing_facts_section(facts) do
    numbered =
      facts
      |> Enum.with_index(1)
      |> Enum.map(fn {fact, i} -> "#{i}. #{fact}" end)
      |> Enum.join("\n")

    """

    ## Existing Facts (already captured — merge with these when the new text refines them)
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
