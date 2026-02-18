defmodule Resume.LLM.Anthropic do
  @moduledoc """
  Anthropic Claude adapter for the LLM behaviour.
  """

  @behaviour Resume.LLM

  alias Resume.LLM.{Pricing, Usage}

  require Logger

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

    start_time = System.monotonic_time(:millisecond)

    case Req.post(@api_url, json: body, headers: headers(), receive_timeout: 120_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        duration_ms = System.monotonic_time(:millisecond) - start_time

        text =
          body
          |> Map.get("content", [])
          |> Enum.find_value(fn
            %{"type" => "text", "text" => text} -> text
            _ -> nil
          end)

        if text do
          usage = build_usage(body, model, duration_ms)

          Logger.info(
            "LLM call model=#{model} input=#{usage.input_tokens} output=#{usage.output_tokens} cost=#{:erlang.float_to_binary(usage.cost_cents, decimals: 4)}¢ duration=#{duration_ms}ms"
          )

          {:ok, text, usage}
        else
          {:error, :no_text_content}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_usage(body, model, duration_ms) do
    api_usage = Map.get(body, "usage", %{})
    input_tokens = Map.get(api_usage, "input_tokens", 0)
    output_tokens = Map.get(api_usage, "output_tokens", 0)
    cache_creation = Map.get(api_usage, "cache_creation_input_tokens", 0)
    cache_read = Map.get(api_usage, "cache_read_input_tokens", 0)

    %Usage{
      model: model,
      input_tokens: input_tokens,
      output_tokens: output_tokens,
      cache_creation_input_tokens: cache_creation,
      cache_read_input_tokens: cache_read,
      cost_cents:
        Pricing.cost_cents(model, input_tokens, output_tokens, cache_creation, cache_read),
      duration_ms: duration_ms
    }
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
