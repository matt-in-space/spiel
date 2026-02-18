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

  describe "profile tab" do
    setup :register_and_log_in_user

    test "renders profile tab by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "Profile Settings"
      assert html =~ "Full Name"
      assert html =~ "Save Changes"
    end

    test "renders form with existing data", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_profile(user, %{
          "name" => "Jane Doe",
          "phone" => "555-1234"
        })

      {:ok, _view, html} = live(conn, ~p"/profile")
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

  describe "tab switching" do
    setup :register_and_log_in_user

    test "defaults to profile tab", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/profile")
      assert html =~ "Full Name"
      refute has_element?(view, ~s(input[name="filter"]))
    end

    test "switches to facts & directives tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      html = render(view)
      assert html =~ "Add details or rules"
      refute html =~ "Full Name"
    end

    test "switches back to profile tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> element(~s(button[phx-value-tab="profile"]))
      |> render_click()

      html = render(view)
      assert html =~ "Full Name"
    end

    test "shows badge with total item count", %{conn: conn, user: user} do
      {:ok, _} = Resume.Accounts.update_user_facts(user, ["Fact 1", "Fact 2"])
      {:ok, _} = Resume.Accounts.update_user_directives(user, ["Directive 1"])

      {:ok, _view, html} = live(conn, ~p"/profile")
      assert html =~ "3"
    end
  end

  describe "facts & directives card grid" do
    setup :register_and_log_in_user

    test "displays facts with Fact badge", %{conn: conn, user: user} do
      {:ok, _} = Resume.Accounts.update_user_facts(user, ["5 years of Elixir experience"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      html = render(view)
      assert html =~ "5 years of Elixir experience"
      assert html =~ "Detail"
    end

    test "displays directives with Rule badge", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_directives(user, ["Always emphasize leadership"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      html = render(view)
      assert html =~ "Always emphasize leadership"
      assert html =~ "Rule"
    end

    test "shows empty state when no items", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      html = render(view)
      assert html =~ "No details or rules yet"
    end

    test "shows facts and directives together", %{conn: conn, user: user} do
      {:ok, _} = Resume.Accounts.update_user_facts(user, ["Worked at Google"])
      {:ok, _} = Resume.Accounts.update_user_directives(user, ["Keep it brief"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      html = render(view)
      assert html =~ "Worked at Google"
      assert html =~ "Keep it brief"
      assert html =~ "Detail"
      assert html =~ "Rule"
    end
  end

  describe "delete items" do
    setup :register_and_log_in_user

    test "deletes a fact", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_facts(user, [
          "5 years of Elixir experience",
          "Led a team of 8 engineers"
        ])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> element(~s(button[phx-click="delete_item"][phx-value-type="fact"][phx-value-index="0"]))
      |> render_click()

      html = render(view)
      refute html =~ "5 years of Elixir experience"
      assert html =~ "Led a team of 8 engineers"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert updated_user.facts == ["Led a team of 8 engineers"]
    end

    test "deletes a directive", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_directives(user, [
          "Highlight cloud skills",
          "Keep resume to one page"
        ])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> element(
        ~s(button[phx-click="delete_item"][phx-value-type="directive"][phx-value-index="0"])
      )
      |> render_click()

      html = render(view)
      refute html =~ "Highlight cloud skills"
      assert html =~ "Keep resume to one page"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert updated_user.directives == ["Keep resume to one page"]
    end
  end

  describe "filter items" do
    setup :register_and_log_in_user

    test "filters items by text content", %{conn: conn, user: user} do
      {:ok, _} =
        Resume.Accounts.update_user_facts(user, [
          "5 years of Elixir experience",
          "Led a team of 8 engineers"
        ])

      {:ok, _} =
        Resume.Accounts.update_user_directives(user, ["Always emphasize leadership"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      # Filter for "elixir" — should match the fact only
      view
      |> form(~s(form[phx-change="filter_items"]), %{"filter" => "elixir"})
      |> render_change()

      html = render(view)
      assert html =~ "5 years of Elixir experience"
      refute html =~ "Led a team of 8 engineers"
      refute html =~ "Always emphasize leadership"
    end

    test "filter is case-insensitive", %{conn: conn, user: user} do
      {:ok, _} = Resume.Accounts.update_user_facts(user, ["Expert in ELIXIR"])

      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> form(~s(form[phx-change="filter_items"]), %{"filter" => "elixir"})
      |> render_change()

      html = render(view)
      assert html =~ "Expert in ELIXIR"
    end
  end

  describe "process input" do
    setup :register_and_log_in_user

    test "processes text input and creates facts and directives", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> form(~s(form[phx-submit="process_input"]),
        input: %{text: "I worked at Google. Always emphasize leadership."}
      )
      |> render_submit()

      # Wait for the async task to complete and re-render
      Process.sleep(100)
      html = render(view)

      assert html =~ "Mock fact from profile input"
      assert html =~ "Mock directive from profile input"
    end

    test "ignores empty input", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view
      |> element(~s(button[phx-value-tab="details_rules"]))
      |> render_click()

      view
      |> form(~s(form[phx-submit="process_input"]), input: %{text: ""})
      |> render_submit()

      html = render(view)
      refute html =~ "Processing input"
    end
  end
end
