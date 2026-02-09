defmodule Resume.Transcription do
  @moduledoc """
  Behaviour for audio transcription providers.

  Abstracts the transcription service so providers (Whisper, Deepgram, etc.)
  can be swapped via configuration.
  """

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

  defp adapter do
    Application.fetch_env!(:resume, :transcription_adapter)
  end
end
