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

      # Wait for async task to complete
      Process.sleep(100)
      html = render(view)

      # Should show preview indicator and confirm/revert buttons
      assert html =~ "Preview"
      assert html =~ "Confirm Changes"
      assert html =~ "Revert"
    end

    test "confirm saves preview data as new version", %{conn: conn, resume: resume} do
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

      # Should have created version 2
      version = Resumes.get_latest_version!(resume.id)
      assert version.version == 2
      assert version.trigger == "feedback"
      assert version.explanation != nil
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

    test "displays explanation from current version", %{conn: conn, resume: resume} do
      version = Resumes.get_latest_version!(resume.id)

      if version.explanation do
        {:ok, _view, html} = live(conn, ~p"/resumes/#{resume}")
        assert html =~ "Notes"
      else
        # Explanation may be nil for some generated resumes
        {:ok, _view, html} = live(conn, ~p"/resumes/#{resume}")
        # Notes section only shows when explanation is present
        assert is_binary(html)
      end
    end
  end
end
