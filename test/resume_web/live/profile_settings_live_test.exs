defmodule ResumeWeb.ProfileSettingsLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /profile" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/profile")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end
  end

  describe "authenticated /profile" do
    setup :register_and_log_in_user

    test "renders form with existing data", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_profile(user, %{
          "name" => "Jane Doe",
          "phone" => "555-1234"
        })

      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "Profile Settings"
      assert html =~ "Jane Doe"
      assert html =~ "555-1234"
    end

    test "saves profile and shows flash", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> form("form", profile: %{name: "Updated Name"})
      |> render_submit()

      html = render(view)
      assert html =~ "Profile updated successfully"
    end

    test "shows error when name is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> form("form", profile: %{name: ""})
      |> render_submit()

      html = render(view)
      assert html =~ "name"
    end
  end
end
