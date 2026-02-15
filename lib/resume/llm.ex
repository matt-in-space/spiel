defmodule Resume.LLM do
  @moduledoc """
  Behaviour for LLM providers.

  Abstracts the LLM interaction so providers (Anthropic, OpenAI, Ollama, etc.)
  can be swapped via configuration.
  """

  alias Resume.LLM.Usage

  require Logger

  @type message :: %{role: String.t(), content: String.t()}

  @doc """
  Sends a prompt to the LLM and returns the response text with usage data.

  ## Options

    * `:system` - System prompt string
    * `:model` - Model identifier (provider-specific)
    * `:max_tokens` - Maximum tokens in the response

  """
  @callback complete(prompt :: String.t(), opts :: keyword()) ::
              {:ok, String.t(), Usage.t()} | {:error, term()}

  @doc """
  Calls the configured LLM adapter's `complete/2`.
  """
  def complete(prompt, opts \\ []) do
    adapter().complete(prompt, opts)
  end

  @doc """
  Calls `complete/2` and persists usage data to the `llm_calls` table.

  The `tracking` map may contain:
    * `:user_id` - ID of the user making the call
    * `:caller` - String identifying the call site (e.g. "facts", "generator")
  """
  def tracked_complete(prompt, opts \\ [], tracking \\ %{}) do
    case complete(prompt, opts) do
      {:ok, text, usage} ->
        persist_call(usage, tracking)
        {:ok, text, usage}

      error ->
        error
    end
  end

  defp persist_call(%Usage{} = usage, tracking) do
    attrs = %{
      user_id: Map.get(tracking, :user_id),
      caller: Map.get(tracking, :caller),
      model: usage.model,
      input_tokens: usage.input_tokens,
      output_tokens: usage.output_tokens,
      cache_creation_input_tokens: usage.cache_creation_input_tokens,
      cache_read_input_tokens: usage.cache_read_input_tokens,
      cost_cents: usage.cost_cents,
      duration_ms: usage.duration_ms
    }

    %Resume.LLM.Call{}
    |> Resume.LLM.Call.changeset(attrs)
    |> Resume.Repo.insert()
    |> case do
      {:ok, _call} ->
        :ok

      {:error, changeset} ->
        Logger.warning("Failed to persist LLM call: #{inspect(changeset.errors)}")
    end
  end

  defp adapter do
    Application.fetch_env!(:resume, :llm_adapter)
  end
end
