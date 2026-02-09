defmodule ResumeWeb.RecordingLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /record" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/record")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end
  end

  describe "authenticated /record" do
    setup :register_and_log_in_user

    test "renders the record page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/record")
      assert html =~ "Record Audio"
      assert html =~ "Record"
    end

    test "toggles recording state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      html = view |> element("button", "Record") |> render_click()
      assert html =~ "Stop Recording"
      assert html =~ "Recording..."

      html = view |> element("button", "Stop Recording") |> render_click()
      assert html =~ "Record"
      refute html =~ "Recording..."
    end

    test "receives audio data and shows transcribing state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      html =
        render_hook(view, "audio_data", %{
          "data" => Base.encode64("fake audio data"),
          "size" => 1234,
          "type" => "audio/webm"
        })

      assert html =~ "Recording #1"
      assert html =~ "1.2 KB"
      assert html =~ "Transcribing..."
    end

    test "displays transcript after transcription completes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      # The mock returns instantly, so the Task completes almost immediately.
      # Give the LV process a moment to receive and handle the task result.
      Process.sleep(50)
      html = render(view)

      assert html =~ "Transcript"
      assert html =~ "mock transcript for testing"
      refute html =~ "Transcribing..."
    end
  end
end
