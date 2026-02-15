defmodule ResumeWeb.ResumesLive.ShowTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Resume.{Accounts, Resumes}

  setup :register_and_log_in_user

  defp create_resume(%{user: user}) do
    {:ok, user} = Accounts.update_user_profile(user, %{"name" => "Test User"})

    {:ok, user} =
      Accounts.update_user_facts(user, ["5 years of Elixir experience"])

    # Complete onboarding so user can access pages
    {:ok, user} = Accounts.complete_onboarding(user, %{"name" => "Test User"}, user.facts)
    {:ok, resume} = Resumes.generate_resume(user, "Test Resume")
    %{user: user, resume: resume}
  end

  describe "feedback UI" do
    setup [:create_resume]

    test "renders feedback input", %{conn: conn, resume: resume} do
      {:ok, _view, html} = live(conn, ~p"/resumes/#{resume}")
      assert html =~ "Suggest changes to your resume"
    end

    test "submit feedback shows processing state then preview", %{conn: conn, resume: resume} do
      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume}")

      view
      |> form(~s(form[phx-submit="send_feedback"]),
        feedback: %{message: "Emphasize cloud skills"}
      )
      |> render_submit()

      # Should show user message and processing indicator
      html = render(view)
      assert html =~ "Emphasize cloud skills"

      # Wait for async task
      Process.sleep(100)
      html = render(view)

      # Should show assistant response and preview indicator
      assert html =~ "Preview"
      assert html =~ "Confirm Changes"
      assert html =~ "Revert"
    end

    test "confirm saves preview data to DB", %{conn: conn, resume: resume} do
      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume}")

      view
      |> form(~s(form[phx-submit="send_feedback"]), feedback: %{message: "Add more detail"})
      |> render_submit()

      Process.sleep(100)
      render(view)

      view
      |> element(~s(button[phx-click="confirm_changes"]))
      |> render_click()

      html = render(view)
      assert html =~ "Changes saved"
      refute html =~ "Preview"

      updated = Resumes.get_resume!(resume.id)
      assert updated.explanation != nil
    end

    test "revert restores original", %{conn: conn, resume: resume} do
      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume}")

      view
      |> form(~s(form[phx-submit="send_feedback"]), feedback: %{message: "Change summary"})
      |> render_submit()

      Process.sleep(100)
      render(view)

      view
      |> element(~s(button[phx-click="revert_changes"]))
      |> render_click()

      html = render(view)
      refute html =~ "Preview"
      refute html =~ "Confirm Changes"
    end
  end

  describe "notes" do
    setup [:create_resume]

    test "displays explanation when present", %{conn: conn, resume: resume} do
      {:ok, updated} =
        Resumes.update_resume(resume, %{explanation: "Focused on web development skills."})

      {:ok, _view, html} = live(conn, ~p"/resumes/#{updated}")
      assert html =~ "Notes"
      assert html =~ "Focused on web development skills"
    end
  end
end
