defmodule ResumeWeb.HomeLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  defp complete_user_onboarding(user) do
    {:ok, user} =
      Resume.Accounts.complete_onboarding(user, %{"name" => "Test User"}, ["A fact"])

    user
  end

  describe "GET /home" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/home")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "renders for onboarded user", %{conn: conn, user: user} do
      complete_user_onboarding(user)
      {:ok, _view, html} = live(conn, ~p"/home")
      assert html =~ "What role are you targeting?"
    end

    test "shows existing resumes", %{conn: conn, user: user} do
      user = complete_user_onboarding(user)

      {:ok, _resume} =
        Resume.Resumes.create_resume(%{
          title: "My Test Resume",
          user_id: user.id,
          data: %{}
        })

      {:ok, _view, html} = live(conn, ~p"/home")
      assert html =~ "My Test Resume"
    end
  end

  describe "resume generation" do
    test "shows error when input is empty", %{conn: conn, user: user} do
      complete_user_onboarding(user)
      {:ok, view, _html} = live(conn, ~p"/home")

      html =
        view
        |> form("form", generate: %{job_target: ""})
        |> render_submit()

      assert html =~ "Please describe the job"
    end

    test "submitting generates and redirects", %{conn: conn, user: user} do
      complete_user_onboarding(user)
      {:ok, view, _html} = live(conn, ~p"/home")

      view
      |> form("form", generate: %{job_target: "Senior Elixir Developer"})
      |> render_submit()

      # Wait for async generation
      Process.sleep(100)

      {path, _flash} = assert_redirect(view)
      assert path =~ "/resumes/"
    end
  end

  describe "resume deletion" do
    test "deletes a resume", %{conn: conn, user: user} do
      user = complete_user_onboarding(user)

      {:ok, resume} =
        Resume.Resumes.create_resume(%{
          title: "To Delete",
          user_id: user.id,
          data: %{}
        })

      {:ok, view, html} = live(conn, ~p"/home")
      assert html =~ "To Delete"

      view
      |> element(~s(button[phx-click="delete"][phx-value-id="#{resume.id}"]))
      |> render_click()

      refute render(view) =~ "To Delete"
    end
  end

  describe "tutorial" do
    test "shows tutorial for onboarded user who hasn't dismissed", %{conn: conn, user: user} do
      complete_user_onboarding(user)
      {:ok, _view, html} = live(conn, ~p"/home")
      assert html =~ "home-tutorial"
    end

    test "does not show tutorial for dismissed user", %{conn: conn, user: user} do
      user = complete_user_onboarding(user)
      Resume.Accounts.dismiss_tutorial(user, "home-tutorial")
      {:ok, _view, html} = live(conn, ~p"/home")
      refute html =~ "home-tutorial"
    end

    test "dismiss_tutorial event hides tutorial and persists", %{conn: conn, user: user} do
      complete_user_onboarding(user)
      {:ok, view, html} = live(conn, ~p"/home")
      assert html =~ "home-tutorial"

      render_hook(view, "dismiss_tutorial", %{"id" => "home-tutorial"})

      refute render(view) =~ "home-tutorial"
      updated_user = Resume.Accounts.get_user!(user.id)
      assert "home-tutorial" in updated_user.dismissed_tutorials
    end
  end
end
