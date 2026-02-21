defmodule Resume.Transcription do
  @moduledoc """
  Behaviour for audio transcription providers.

  Abstracts the transcription service so providers (Whisper, Deepgram, etc.)
  can be swapped via configuration.
  """

  require Logger

  alias Resume.LLM.Call
  alias Resume.Repo

  @doc """
  Transcribes audio binary data to text.

  ## Options

    * `:language` - Language code (default: "en")
    * `:content_type` - MIME type of the audio (default: "audio/webm")

  """
  @callback transcribe(audio_binary :: binary(), opts :: keyword()) ::
              {:ok, String.t()} | {:error, term()}

  @doc """
  Calls the configured transcription adapter's `transcribe/2`.
  """
  def transcribe(audio_binary, opts \\ []) do
    adapter().transcribe(audio_binary, opts)
  end

  @doc """
  Calls `transcribe/2` and persists usage data to the `llm_calls` table.

  The `tracking` map may contain:
    * `:user_id` - ID of the user making the call
    * `:caller` - String identifying the call site (e.g. "transcription")
  """
  def tracked_transcribe(audio_binary, opts \\ [], tracking \\ %{}) do
    start = System.monotonic_time(:millisecond)

    case transcribe(audio_binary, opts) do
      {:ok, _text} = result ->
        duration_ms = System.monotonic_time(:millisecond) - start
        persist_transcription_call(audio_binary, duration_ms, tracking)
        result

      error ->
        error
    end
  end

  # Whisper pricing: $0.006 per minute of audio.
  # We estimate audio duration from byte size assuming ~32 kbps (typical
  # for webm/opus from MediaRecorder), which gives ~4 KB/s.
  @bytes_per_second 4_000
  @whisper_cost_per_minute_usd 0.006

  defp estimate_cost_cents(audio_binary) do
    seconds = byte_size(audio_binary) / @bytes_per_second
    minutes = seconds / 60
    minutes * @whisper_cost_per_minute_usd * 100
  end

  defp persist_transcription_call(audio_binary, duration_ms, tracking) do
    attrs = %{
      user_id: Map.get(tracking, :user_id),
      caller: Map.get(tracking, :caller, "transcription"),
      model: "whisper-1",
      input_tokens: 0,
      output_tokens: 0,
      cache_creation_input_tokens: 0,
      cache_read_input_tokens: 0,
      cost_cents: estimate_cost_cents(audio_binary),
      duration_ms: duration_ms
    }

    %Call{}
    |> Call.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, _call} ->
        :ok

      {:error, changeset} ->
        Logger.warning("Failed to persist transcription call: #{inspect(changeset.errors)}")
    end
  end

  defp adapter do
    Application.fetch_env!(:resume, :transcription_adapter)
  end
end
