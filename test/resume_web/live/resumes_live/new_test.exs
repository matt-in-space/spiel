defmodule ResumeWeb.ResumesLive.NewTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Resume.{Accounts, JobPostings}

  setup :register_and_log_in_user

  defp complete_onboarding(%{user: user}) do
    {:ok, user} = Accounts.update_user_profile(user, %{"name" => "Test User"})
    {:ok, user} = Accounts.update_user_facts(user, ["5 years of Elixir experience"])
    {:ok, user} = Accounts.complete_onboarding(user, %{"name" => "Test User"}, user.facts)
    %{user: user}
  end

  describe "new resume form" do
    setup [:complete_onboarding]

    test "renders the form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/resumes/new")

      assert html =~ "New Resume"
      assert html =~ "Job Posting URL"
      assert html =~ "Job Description or Desired Role"
      assert html =~ "Generate Resume"
    end

    test "URL fetch failure shows paste fallback", %{conn: conn} do
      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, "<p>JavaScript must be enabled</p>")
      end)

      {:ok, view, _html} = live(conn, ~p"/resumes/new")

      view
      |> form("form", resume: %{job_posting_url: "https://example.com/job"})
      |> render_submit()

      # Wait for async fetch task
      Process.sleep(100)
      html = render(view)

      assert html =~ "We couldn&#39;t read that page"
      assert html =~ "Paste the job description below"
      # Form should still be visible (not the spinner)
      assert html =~ "Generate Resume"
    end

    test "submitting with pasted text generates directly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/resumes/new")

      html =
        view
        |> form("form",
          resume: %{
            job_posting_text:
              "Senior Elixir Developer needed with 5+ years experience building Phoenix applications."
          }
        )
        |> render_submit()

      # Should show generating spinner immediately (not fetching URL)
      assert html =~ "Generating your resume"
      refute html =~ "Fetching job posting"
    end
  end
end
