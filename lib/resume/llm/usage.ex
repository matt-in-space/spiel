defmodule Resume.LLM.Usage do
  @moduledoc """
  Token usage and cost data from an LLM API call.
  """

  defstruct model: nil,
            input_tokens: 0,
            output_tokens: 0,
            cache_creation_input_tokens: 0,
            cache_read_input_tokens: 0,
            cost_cents: 0.0,
            duration_ms: 0

  @type t :: %__MODULE__{
          model: String.t() | nil,
          input_tokens: non_neg_integer(),
          output_tokens: non_neg_integer(),
          cache_creation_input_tokens: non_neg_integer(),
          cache_read_input_tokens: non_neg_integer(),
          cost_cents: float(),
          duration_ms: non_neg_integer()
        }
end
