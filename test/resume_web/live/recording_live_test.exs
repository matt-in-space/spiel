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

    test "shows Extract Facts button after transcription completes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      Process.sleep(50)
      html = render(view)

      assert html =~ "Extract Facts"
    end

    test "extract facts advances to review phase", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      Process.sleep(50)

      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()

      # Wait for async LLM extraction (mock is very fast)
      Process.sleep(100)
      html = render(view)

      assert html =~ "Review Extracted Facts"
      assert html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end

    test "remove operation from review list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      Process.sleep(50)
      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()
      Process.sleep(100)

      html = render(view)
      assert html =~ "Mock fact about career"

      view
      |> element(~s(button[phx-click="remove_operation"][phx-value-index="0"]))
      |> render_click()

      html = render(view)

      refute html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end

    test "save facts redirects to / with flash", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      Process.sleep(50)
      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()
      Process.sleep(100)

      view |> element(~s(button[phx-click="save_facts"])) |> render_click()
      flash = assert_redirect(view, ~p"/")
      assert flash["info"] =~ "Saved 2 changes"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert "Mock fact about career" in updated_user.facts
      assert "Mock fact about skills" in updated_user.facts
    end

    test "start over resets to recording phase", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/record")

      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      Process.sleep(50)
      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()
      Process.sleep(100)

      assert render(view) =~ "Review Extracted Facts"

      view |> element(~s(button[phx-click="start_over"])) |> render_click()
      html = render(view)

      assert html =~ "Record Audio"
      refute html =~ "Review Extracted Facts"
      refute html =~ "Recording #1"
    end
  end
end
