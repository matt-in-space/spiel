defmodule ResumeWeb.OnboardingLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Resume.AccountsFixtures

  describe "GET /onboarding" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/onboarding")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "redirects already-onboarded users to /", %{conn: conn} do
      user = user_fixture()

      {:ok, _user} =
        Resume.Accounts.complete_onboarding(user, %{"name" => "Test"}, ["A fact"])

      conn = log_in_user(conn, user)
      assert {:error, redirect} = live(conn, ~p"/onboarding")
      assert {:redirect, %{to: "/"}} = redirect
    end
  end

  describe "profile step" do
    setup :register_and_log_in_user

    test "renders profile form at step 1", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/onboarding")
      assert html =~ "Tell us about yourself"
      assert html =~ "Full Name"
    end

    test "pre-fills email from user", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/onboarding")
      assert html =~ user.email
    end

    test "requires name to advance", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      html =
        view
        |> form("form", profile: %{name: "", email: "test@test.com"})
        |> render_submit()

      # Should stay on profile step and show error
      assert html =~ "Tell us about yourself" || has_element?(view, ".alert-error")
    end

    test "advances to current_role on valid submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view
      |> form("form", profile: %{name: "Jane Doe", email: "jane@test.com"})
      |> render_submit()

      html = render(view)
      assert html =~ "Current / Most Recent Role"
    end
  end

  describe "recording steps" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Advance past profile step
      view
      |> form("form", profile: %{name: "Jane Doe", email: "jane@test.com"})
      |> render_submit()

      %{view: view}
    end

    test "renders current role step", %{view: view} do
      html = render(view)
      assert html =~ "Current / Most Recent Role"
      assert html =~ "Record"
    end

    test "toggles recording state", %{view: view} do
      html = view |> element("button", "Record") |> render_click()
      assert html =~ "Stop Recording"
      assert html =~ "Recording..."

      html = view |> element("button", "Stop Recording") |> render_click()
      assert html =~ "Record"
    end

    test "receives audio data and shows transcribing state", %{view: view} do
      html =
        render_hook(view, "audio_data", %{
          "data" => Base.encode64("fake audio data"),
          "size" => 1234,
          "type" => "audio/webm"
        })

      assert html =~ "Recording #1"
      assert html =~ "Transcribing..."
    end

    test "next button advances step with no recordings", %{view: view} do
      view |> element("button", "Next") |> render_click()

      # Wait for async extraction
      Process.sleep(50)
      html = render(view)
      assert html =~ "Previous Experience"
    end

    test "skip button advances step", %{view: view} do
      # First advance to a skippable step (previous_roles)
      view |> element("button", "Next") |> render_click()
      Process.sleep(50)
      html = render(view)
      assert html =~ "Previous Experience"

      view |> element("button", "Skip") |> render_click()
      html = render(view)
      assert html =~ "Education"
    end

    test "next with transcripts triggers fact extraction", %{view: view} do
      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio data"),
        "size" => 1234,
        "type" => "audio/webm"
      })

      # Wait for transcription to complete
      Process.sleep(50)
      html = render(view)
      assert html =~ "mock transcript"

      view |> element("button", "Next") |> render_click()

      # Wait for LLM extraction
      Process.sleep(50)
      html = render(view)

      # Should have advanced to next step
      assert html =~ "Previous Experience"
    end
  end

  describe "review step" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Advance past profile
      view
      |> form("form", profile: %{name: "Jane Doe", email: "jane@test.com"})
      |> render_submit()

      # Record at current_role step
      render_hook(view, "audio_data", %{
        "data" => Base.encode64("fake audio"),
        "size" => 100,
        "type" => "audio/webm"
      })

      # Wait for transcription to complete
      Process.sleep(100)

      view |> element("button", "Next") |> render_click()

      # Wait for LLM extraction to complete and step to advance
      Process.sleep(100)

      # Skip through remaining steps (previous_roles → education → skills → review)
      view |> element("button", "Skip") |> render_click()
      view |> element("button", "Skip") |> render_click()
      view |> element("button", "Skip") |> render_click()

      %{view: view}
    end

    test "shows review step with extracted facts", %{view: view} do
      html = render(view)
      assert html =~ "Review Your Facts"
      assert html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end

    test "remove button removes a fact", %{view: view} do
      html = render(view)
      assert html =~ "Mock fact about career"

      view |> element(~s(button[phx-click="remove_fact"][phx-value-index="0"])) |> render_click()
      html = render(view)

      refute html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end

    test "complete onboarding saves and redirects", %{view: view} do
      # Verify we're at review step and can complete
      assert render(view) =~ "Review Your Facts"

      view |> element("button", "Save & Continue") |> render_click()
      flash = assert_redirect(view, ~p"/")
      assert flash["info"] =~ "Welcome"
    end
  end

  describe "complete onboarding (simple)" do
    setup :register_and_log_in_user

    test "saves profile and facts and redirects to /", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Fill in profile and advance
      view
      |> form("form", profile: %{name: "Jane Doe"})
      |> render_submit()

      # Skip all recording steps to reach review
      view |> element("button", "Next") |> render_click()
      Process.sleep(50)
      view |> element("button", "Skip") |> render_click()
      view |> element("button", "Skip") |> render_click()
      view |> element("button", "Skip") |> render_click()

      assert render(view) =~ "Review Your Facts"

      view |> element("button", "Save & Continue") |> render_click()
      flash = assert_redirect(view, ~p"/")
      assert flash["info"] =~ "Welcome"
    end
  end
end
