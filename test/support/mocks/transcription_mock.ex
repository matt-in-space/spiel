defmodule Resume.Transcription.Mock do
  @moduledoc """
  Mock transcription adapter for tests.
  """

  @behaviour Resume.Transcription

  @impl true
  def transcribe(_audio_binary, _opts \\ []) do
    {:ok, "This is a mock transcript for testing purposes."}
  end
end
