defmodule Resume.Transcription.OpenAIWhisper do
  @moduledoc """
  OpenAI Whisper API adapter for the Transcription behaviour.

  Uses the OpenAI audio transcription endpoint.
  Requires an `OPENAI_API_KEY` environment variable.
  """

  require Logger

  @behaviour Resume.Transcription

  @url "https://api.openai.com/v1/audio/transcriptions"

  @impl true
  def transcribe(audio_binary, opts \\ []) do
    {language, opts} = Keyword.pop(opts, :language, "en")
    {content_type, _opts} = Keyword.pop(opts, :content_type, "audio/webm")

    extension =
      case content_type do
        "audio/webm" <> _ -> ".webm"
        "audio/ogg" <> _ -> ".ogg"
        "audio/wav" <> _ -> ".wav"
        "audio/mp4" <> _ -> ".m4a"
        _ -> ".webm"
      end

    case Req.post(@url,
           headers: [{"authorization", "Bearer #{api_key()}"}],
           form_multipart: [
             file: {audio_binary, filename: "audio#{extension}", content_type: content_type},
             model: "whisper-1",
             language: language,
             response_format: "json"
           ]
         ) do
      {:ok, %Req.Response{status: 200, body: %{"text" => text}}} ->
        {:ok, String.trim(text)}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("OpenAI Whisper API returned #{status}: #{inspect(body)}")
        {:error, {status, body}}

      {:error, reason} ->
        Logger.error("OpenAI Whisper API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp api_key do
    Application.fetch_env!(:resume, :openai_api_key)
  end
end
