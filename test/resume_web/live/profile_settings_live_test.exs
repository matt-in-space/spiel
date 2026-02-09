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
      |> form(~s(form[phx-submit="save"]), profile: %{name: "Updated Name"})
      |> render_submit()

      html = render(view)
      assert html =~ "Profile updated successfully"
    end

    test "shows error when name is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> form(~s(form[phx-submit="save"]), profile: %{name: ""})
      |> render_submit()

      html = render(view)
      assert html =~ "name"
    end
  end

  describe "facts management" do
    setup :register_and_log_in_user

    test "renders saved facts on profile page", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, [
          "5 years of Elixir experience",
          "Led a team of 8 engineers"
        ])

      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "Your Facts"
      assert html =~ "5 years of Elixir experience"
      assert html =~ "Led a team of 8 engineers"
      assert html =~ "2"
    end

    test "shows empty state when no facts", %{conn: conn, user: user} do
      {:ok, _user} = Resume.Accounts.update_user_facts(user, [])
      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "No facts yet"
    end

    test "delete removes a fact and persists", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, [
          "5 years of Elixir experience",
          "Led a team of 8 engineers"
        ])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-click="delete_fact"][phx-value-index="0"]))
      |> render_click()

      html = render(view)
      refute html =~ "5 years of Elixir experience"
      assert html =~ "Led a team of 8 engineers"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert updated_user.facts == ["Led a team of 8 engineers"]
    end

    test "edit switches to inline input with current text", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-click="edit_fact"][phx-value-index="0"]))
      |> render_click()

      html = render(view)
      assert html =~ "5 years of Elixir experience"
      assert has_element?(view, ~s(button[aria-label="Save edit"]))
      assert has_element?(view, ~s(button[aria-label="Cancel edit"]))
    end

    test "save edit persists the change", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-click="edit_fact"][phx-value-index="0"]))
      |> render_click()

      view
      |> form(~s(form[phx-submit="save_edit"]), edit: %{text: "10 years of Elixir experience"})
      |> render_submit()

      html = render(view)
      assert html =~ "10 years of Elixir experience"
      refute html =~ "5 years of Elixir experience"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert updated_user.facts == ["10 years of Elixir experience"]
    end

    test "cancel edit returns to display mode", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-click="edit_fact"][phx-value-index="0"]))
      |> render_click()

      view
      |> element(~s(button[phx-click="cancel_edit"]))
      |> render_click()

      html = render(view)
      assert html =~ "5 years of Elixir experience"
      refute has_element?(view, ~s(button[aria-label="Save edit"]))
    end

    test "add new fact appends to list and persists", %{conn: conn, user: user} do
      {:ok, _user} =
        Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> form(~s(form[phx-submit="add_fact"]), new_fact: %{text: "Expert in distributed systems"})
      |> render_submit()

      html = render(view)
      assert html =~ "5 years of Elixir experience"
      assert html =~ "Expert in distributed systems"

      updated_user = Resume.Accounts.get_user!(user.id)

      assert updated_user.facts == [
               "5 years of Elixir experience",
               "Expert in distributed systems"
             ]
    end
  end
end
