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

    test "redirects already-onboarded users with facts to /home", %{conn: conn} do
      user = user_fixture()

      {:ok, _user} =
        Resume.Accounts.complete_onboarding(user, %{"name" => "Test"}, ["A fact"])

      conn = log_in_user(conn, user)
      assert {:error, redirect} = live(conn, ~p"/onboarding")
      assert {:redirect, %{to: "/home"}} = redirect
    end

    test "allows re-entry for onboarded users with 0 facts", %{conn: conn} do
      user = user_fixture()
      {:ok, _user} = Resume.Accounts.complete_onboarding(user, %{"name" => "Test"}, [])

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/onboarding")
      # Should land on interview step directly
      assert html =~ "Career Interview"
    end
  end

  describe "contact step" do
    setup :register_and_log_in_user

    test "renders contact form at step 1", %{conn: conn} do
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
        |> form("form[phx-submit='save_profile']", profile: %{name: "", email: "test@test.com"})
        |> render_submit()

      assert html =~ "Tell us about yourself" || has_element?(view, ".alert-error")
    end

    test "advances to import on valid submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view
      |> form("form[phx-submit='save_profile']",
        profile: %{name: "Jane Doe", email: "jane@test.com"}
      )
      |> render_submit()

      html = render(view)
      assert html =~ "Share Your Background"
    end
  end

  describe "import step" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      view
      |> form("form[phx-submit='save_profile']",
        profile: %{name: "Jane Doe", email: "jane@test.com"}
      )
      |> render_submit()

      %{view: view}
    end

    test "renders import step", %{view: view} do
      html = render(view)
      assert html =~ "Share Your Background"
      assert html =~ "Skip"
    end

    test "skip advances to interview", %{view: view} do
      view |> element("button", "Skip") |> render_click()

      Process.sleep(100)
      html = render(view)
      assert html =~ "Career Interview"
    end

    test "text paste triggers extraction and shows count", %{view: view} do
      view
      |> form("form[phx-submit='submit_import']",
        paste: %{text: "I worked at Acme Corp for 5 years as a senior engineer."}
      )
      |> render_submit()

      Process.sleep(100)
      html = render(view)
      assert html =~ "Extracted"
      assert html =~ "details"
    end

    test "continue after import advances to interview", %{view: view} do
      view
      |> form("form[phx-submit='submit_import']",
        paste: %{text: "I worked at Acme Corp for 5 years."}
      )
      |> render_submit()

      Process.sleep(100)

      view |> element("button", "Continue") |> render_click()

      Process.sleep(100)
      html = render(view)
      assert html =~ "Career Interview"
    end
  end

  describe "interview step" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Advance past contact
      view
      |> form("form[phx-submit='save_profile']",
        profile: %{name: "Jane Doe", email: "jane@test.com"}
      )
      |> render_submit()

      # Skip import
      view |> element("button", "Skip") |> render_click()

      Process.sleep(100)

      %{view: view}
    end

    test "displays opening question", %{view: view} do
      html = render(view)
      assert html =~ "Career Interview"
      assert html =~ "what do you do now"
    end

    test "sending a message gets a response", %{view: view} do
      view
      |> form("form[phx-submit='send_message']",
        chat: %{message: "I work at Acme Corp as an engineer"}
      )
      |> render_submit()

      Process.sleep(100)
      html = render(view)
      assert html =~ "technologies"
    end

    test "skip advances to recap", %{view: view} do
      view |> element("button", "Skip") |> render_click()

      html = render(view)
      assert html =~ "Your Profile Summary"
    end

    test "I'm done advances to recap", %{view: view} do
      view |> element(~s(button[phx-click="interview_done"])) |> render_click()

      html = render(view)
      assert html =~ "Your Profile Summary"
    end
  end

  describe "recap step" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Advance through contact
      view
      |> form("form[phx-submit='save_profile']",
        profile: %{name: "Jane Doe", email: "jane@test.com"}
      )
      |> render_submit()

      # Paste text to get some facts
      view
      |> form("form[phx-submit='submit_import']",
        paste: %{text: "I worked at Acme Corp for 5 years as a senior engineer."}
      )
      |> render_submit()

      Process.sleep(100)

      # Continue from import
      view |> element("button", "Continue") |> render_click()

      Process.sleep(100)

      # Skip interview
      view |> element("button", "Skip") |> render_click()

      Process.sleep(100)

      %{view: view}
    end

    test "shows recap summary", %{view: view} do
      html = render(view)
      assert html =~ "Your Profile Summary"
      assert html =~ "experienced professional" || html =~ "Complete Setup"
    end

    test "complete saves and redirects to /home with few facts", %{view: view} do
      view |> element("button", "Complete Setup") |> render_click()
      flash = assert_redirect(view, ~p"/home")
      assert flash["info"] =~ "Welcome"
    end
  end

  describe "complete onboarding (simple path)" do
    setup :register_and_log_in_user

    test "skip everything and complete", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Fill in contact
      view
      |> form("form[phx-submit='save_profile']", profile: %{name: "Jane Doe"})
      |> render_submit()

      # Skip import
      view |> element("button", "Skip") |> render_click()
      Process.sleep(100)

      # Skip interview
      view |> element("button", "Skip") |> render_click()

      assert render(view) =~ "Your Profile Summary"

      view |> element("button", "Complete Setup") |> render_click()
      flash = assert_redirect(view, ~p"/home")
      assert flash["info"] =~ "Welcome"
    end
  end

  describe "auto-generate resume on complete" do
    setup :register_and_log_in_user

    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/onboarding")

      # Advance through contact
      view
      |> form("form[phx-submit='save_profile']",
        profile: %{name: "Jane Doe", email: "jane@test.com"}
      )
      |> render_submit()

      # Import text to get 2 facts
      view
      |> form("form[phx-submit='submit_import']",
        paste: %{text: "I worked at Acme Corp for 5 years as a senior engineer."}
      )
      |> render_submit()

      Process.sleep(100)

      # Continue from import
      view |> element("button", "Continue") |> render_click()
      Process.sleep(100)

      # Skip interview
      view |> element("button", "Skip") |> render_click()
      Process.sleep(100)

      # Submit corrections to accumulate >= 5 facts
      view
      |> form("form[phx-submit='submit_correction']", recap: %{correction: "I also know Python"})
      |> render_submit()

      Process.sleep(100)

      view
      |> form("form[phx-submit='submit_correction']",
        recap: %{correction: "I have a CS degree from MIT"}
      )
      |> render_submit()

      Process.sleep(100)

      %{view: view}
    end

    test "auto-generates resume and redirects", %{view: view} do
      view |> element("button", "Complete Setup") |> render_click()

      # Should show the loading state
      html = render(view)
      assert html =~ "Building your first personalized resume"

      # Wait for async generation
      Process.sleep(200)

      {path, flash} = assert_redirect(view)
      assert path =~ "/resumes/"
      assert flash["info"] =~ "first resume"
    end
  end
end
