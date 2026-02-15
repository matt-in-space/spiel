defmodule Resume.LLM.Pricing do
  @moduledoc """
  Model pricing lookup and cost calculation for LLM API calls.

  Prices are per million tokens in USD.
  """

  @prices %{
    "claude-sonnet-4-5-20250929" => %{
      input: 3.0,
      output: 15.0,
      cache_write: 3.75,
      cache_read: 0.30
    },
    "claude-haiku-3-5-20241022" => %{
      input: 0.80,
      output: 4.0,
      cache_write: 1.00,
      cache_read: 0.08
    }
  }

  @doc """
  Calculates the total cost in cents for a given model and token counts.

  Returns 0.0 for unknown models.
  """
  @spec cost_cents(
          String.t(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) ::
          float()
  def cost_cents(
        model,
        input_tokens,
        output_tokens,
        cache_creation_tokens \\ 0,
        cache_read_tokens \\ 0
      ) do
    case Map.get(@prices, model) do
      nil ->
        0.0

      prices ->
        (tokens_cost(input_tokens, prices.input) +
           tokens_cost(output_tokens, prices.output) +
           tokens_cost(cache_creation_tokens, prices.cache_write) +
           tokens_cost(cache_read_tokens, prices.cache_read)) * 100
    end
  end

  defp tokens_cost(tokens, price_per_mtok) do
    tokens / 1_000_000 * price_per_mtok
  end
end
