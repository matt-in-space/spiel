defmodule Resume.Transcription.WhisperTest do
  use ExUnit.Case, async: true

  alias Resume.Transcription.Whisper

  describe "transcribe/2" do
    test "returns transcript text on success" do
      Req.Test.stub(Whisper, fn conn ->
        assert conn.method == "POST"
        assert conn.query_string =~ "task=transcribe"
        assert conn.query_string =~ "language=en"
        assert conn.query_string =~ "output=json"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"text" => " Hello, world! "}))
      end)

      assert {:ok, "Hello, world!"} =
               Whisper.transcribe("fake audio bytes", plug: {Req.Test, Whisper})
    end

    test "returns error on non-200 status" do
      Req.Test.stub(Whisper, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, Jason.encode!(%{"error" => "internal error"}))
      end)

      assert {:error, {500, _body}} =
               Whisper.transcribe("fake audio bytes", plug: {Req.Test, Whisper})
    end
  end
end
