defmodule Resume.LLM.Anthropic do
  @moduledoc """
  Anthropic Claude adapter for the LLM behaviour.
  """

  @behaviour Resume.LLM

  @default_model "claude-sonnet-4-5-20250929"
  @default_max_tokens 4096
  @api_url "https://api.anthropic.com/v1/messages"

  @impl true
  def complete(prompt, opts \\ []) do
    model = Keyword.get(opts, :model, @default_model)
    max_tokens = Keyword.get(opts, :max_tokens, @default_max_tokens)
    system = Keyword.get(opts, :system)

    body =
      %{
        model: model,
        max_tokens: max_tokens,
        messages: [%{role: "user", content: prompt}]
      }
      |> maybe_put(:system, system)

    case Req.post(@api_url, json: body, headers: headers(), receive_timeout: 120_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        text =
          body
          |> Map.get("content", [])
          |> Enum.find_value(fn
            %{"type" => "text", "text" => text} -> text
            _ -> nil
          end)

        if text, do: {:ok, text}, else: {:error, :no_text_content}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp headers do
    [
      {"x-api-key", api_key()},
      {"anthropic-version", "2023-06-01"}
    ]
  end

  defp api_key do
    Application.fetch_env!(:resume, :anthropic_api_key)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
