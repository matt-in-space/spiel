defmodule Resume.Transcription.Whisper do
  @moduledoc """
  Whisper ASR adapter for the Transcription behaviour.

  Sends audio to the `onerahmet/openai-whisper-asr-webservice` Docker service.
  """

  @behaviour Resume.Transcription

  @impl true
  def transcribe(audio_binary, opts \\ []) do
    {language, opts} = Keyword.pop(opts, :language, "en")
    {content_type, opts} = Keyword.pop(opts, :content_type, "audio/webm")

    extension =
      case content_type do
        "audio/webm" <> _ -> ".webm"
        "audio/ogg" <> _ -> ".ogg"
        "audio/wav" <> _ -> ".wav"
        "audio/mp4" <> _ -> ".m4a"
        _ -> ".webm"
      end

    url = "#{whisper_url()}/asr?task=transcribe&language=#{language}&output=json"

    req_opts =
      Keyword.merge(opts,
        form_multipart: [
          audio_file: {audio_binary, filename: "audio#{extension}", content_type: content_type}
        ]
      )

    case Req.post(url, req_opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        parse_response(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Whisper returns content-type: text/plain, so Req won't auto-decode JSON.
  # Handle both parsed maps (from tests with Req.Test) and raw strings.
  defp parse_response(%{"text" => text}), do: {:ok, String.trim(text)}

  defp parse_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"text" => text}} -> {:ok, String.trim(text)}
      _ -> {:error, {:invalid_response, body}}
    end
  end

  defp parse_response(body), do: {:error, {:unexpected_body, body}}

  defp whisper_url do
    Application.fetch_env!(:resume, :whisper_url)
  end
end
