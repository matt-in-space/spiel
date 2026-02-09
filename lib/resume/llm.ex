defmodule Resume.LLM do
  @moduledoc """
  Behaviour for LLM providers.

  Abstracts the LLM interaction so providers (Anthropic, OpenAI, Ollama, etc.)
  can be swapped via configuration.
  """

  @type message :: %{role: String.t(), content: String.t()}

  @doc """
  Sends a prompt to the LLM and returns the response text.

  ## Options

    * `:system` - System prompt string
    * `:model` - Model identifier (provider-specific)
    * `:max_tokens` - Maximum tokens in the response

  """
  @callback complete(prompt :: String.t(), opts :: keyword()) ::
              {:ok, String.t()} | {:error, term()}

  @doc """
  Calls the configured LLM adapter's `complete/2`.
  """
  def complete(prompt, opts \\ []) do
    adapter().complete(prompt, opts)
  end

  defp adapter do
    Application.fetch_env!(:resume, :llm_adapter)
  end
end
