defmodule ResumeWeb.ResumesLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Resume.AccountsFixtures

  alias Resume.{Accounts, Resumes}

  defp create_resume(user, title, opts \\ []) do
    {:ok, user} = Accounts.update_user_profile(user, %{"name" => "Test User"})
    {:ok, resume} = Resumes.generate_resume(user, title, opts)
    resume
  end

  describe "Index" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/resumes")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "shows empty state when no resumes", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/resumes")
      assert html =~ "No resumes yet"
    end

    test "lists user resumes", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      resume = create_resume(user, "My First Resume")

      {:ok, _view, html} = live(conn, ~p"/resumes")
      assert html =~ "My First Resume"
      assert html =~ "View"
      refute html =~ "No resumes yet"

      # Check for the resume link
      assert html =~ ~p"/resumes/#{resume}"
    end

    test "shows targeted badge for resumes with job posting", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      create_resume(user, "Targeted Resume", job_posting_text: "Elixir dev needed")

      {:ok, _view, html} = live(conn, ~p"/resumes")
      assert html =~ "Targeted"
    end

    test "deletes a resume", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      create_resume(user, "Delete Me")

      {:ok, view, html} = live(conn, ~p"/resumes")
      assert html =~ "Delete Me"

      view |> element(~s(button[phx-click="delete"])) |> render_click()
      html = render(view)
      refute html =~ "Delete Me"
      assert html =~ "No resumes yet"
    end
  end

  describe "New" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/resumes/new")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "renders form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/resumes/new")
      assert html =~ "New Resume"
      assert html =~ "Title"
      assert html =~ "Generate Resume"
    end

    test "shows error when title is empty", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/resumes/new")

      html =
        view
        |> form("form", resume: %{title: ""})
        |> render_submit()

      assert html =~ "Title is required"
    end

    test "generates resume and redirects to show", %{conn: conn} do
      user = user_fixture()
      {:ok, _user} = Accounts.update_user_profile(user, %{"name" => "Test User"})
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/resumes/new")

      view
      |> form("form", resume: %{title: "Generated Resume"})
      |> render_submit()

      # Wait for async generation
      Process.sleep(100)
      {path, _flash} = assert_redirect(view)
      assert path =~ ~r"/resumes/\d+"
    end
  end

  describe "Show" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/resumes/999")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "displays resume content", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      resume = create_resume(user, "My Resume")

      {:ok, _view, html} = live(conn, ~p"/resumes/#{resume}")
      assert html =~ "My Resume"
      assert html =~ "Test User"
      assert html =~ "Summary"
      assert html =~ "Experienced software engineer"
      assert html =~ "Work Experience"
      assert html =~ "Senior Software Engineer"
      assert html =~ "Acme Corp"
      assert html =~ "Education"
      assert html =~ "Skills"
    end

    test "delete redirects to index", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      resume = create_resume(user, "Delete Me")

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume}")

      view |> element(~s(button[phx-click="delete"])) |> render_click()
      flash = assert_redirect(view, ~p"/resumes")
      assert flash["info"] =~ "deleted"
    end

    test "regenerate updates resume data", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      resume = create_resume(user, "Regen Me")

      {:ok, view, _html} = live(conn, ~p"/resumes/#{resume}")

      view |> element(~s(button[phx-click="regenerate"])) |> render_click()

      # Wait for async regeneration
      Process.sleep(100)
      html = render(view)
      assert html =~ "Resume regenerated"
    end

    test "user cannot view another user's resume", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      resume = create_resume(user1, "Private Resume")

      conn = log_in_user(conn, user2)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/resumes/#{resume}")
      end
    end
  end
end
