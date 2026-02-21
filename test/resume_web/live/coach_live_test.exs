defmodule ResumeWeb.CoachLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /coach" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/coach")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end
  end

  describe "coach chat phase" do
    setup :register_and_log_in_user

    setup %{user: user} do
      # Give user some existing facts so the coach has context
      {:ok, user} =
        Resume.Accounts.update_user_facts(user, [
          "Works as a software engineer at Acme Corp",
          "Has 5 years of experience with Python"
        ])

      %{user: user}
    end

    test "renders coach page with opening question", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/coach")
      assert html =~ "Career Coach"

      Process.sleep(100)
      html = render(view)
      assert html =~ "career lately"
    end

    test "sends message and receives response", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      view
      |> form("form[phx-submit='send_message']",
        chat: %{message: "I got promoted to senior engineer"}
      )
      |> render_submit()

      Process.sleep(100)
      html = render(view)
      assert html =~ "technologies"
    end

    test "ignores empty messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      view
      |> form("form[phx-submit='send_message']", chat: %{message: ""})
      |> render_submit()

      # Should still only have the opening message
      html = render(view)
      assert html =~ "career lately"
    end

    test "finish_chat transitions to review phase", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      view |> element(~s(button[phx-click="finish_chat"])) |> render_click()

      html = render(view)
      assert html =~ "Review Changes"
    end

    test "back_to_chat returns to chat phase", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      view |> element(~s(button[phx-click="finish_chat"])) |> render_click()
      assert render(view) =~ "Review Changes"

      view |> element(~s(button[phx-click="back_to_chat"])) |> render_click()

      html = render(view)
      assert html =~ "Career Coach"
      refute html =~ "Review Changes"
    end
  end

  describe "coach confirm" do
    setup :register_and_log_in_user

    setup %{user: user} do
      {:ok, user} =
        Resume.Accounts.update_user_facts(user, [
          "Works as a software engineer at Acme Corp"
        ])

      %{user: user}
    end

    test "confirm_changes saves facts and redirects", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      # Send a message to generate some changes
      view
      |> form("form[phx-submit='send_message']",
        chat: %{message: "I recently learned Elixir and Phoenix"}
      )
      |> render_submit()

      Process.sleep(100)

      # Go to review
      view |> element(~s(button[phx-click="finish_chat"])) |> render_click()

      # Confirm changes
      view |> element(~s(button[phx-click="confirm_changes"])) |> render_click()

      flash = assert_redirect(view, ~p"/profile?tab=details_rules")
      assert flash["info"] =~ "Saved"

      # Verify facts were persisted
      updated_user = Resume.Repo.get!(Resume.Accounts.User, user.id)
      assert length(updated_user.facts) > 1
    end
  end

  describe "discard safety" do
    setup :register_and_log_in_user

    setup %{user: user} do
      original_facts = ["Original fact that should remain"]

      {:ok, user} = Resume.Accounts.update_user_facts(user, original_facts)

      %{user: user, original_facts: original_facts}
    end

    test "navigating away does not save facts", %{
      conn: conn,
      user: user,
      original_facts: original_facts
    } do
      {:ok, view, _html} = live(conn, ~p"/coach")

      Process.sleep(100)

      # Send a message
      view
      |> form("form[phx-submit='send_message']",
        chat: %{message: "I switched to a DevOps role"}
      )
      |> render_submit()

      Process.sleep(100)

      # Navigate away without confirming (simulated by not clicking confirm)
      # The facts in DB should remain unchanged
      updated_user = Resume.Repo.get!(Resume.Accounts.User, user.id)
      assert updated_user.facts == original_facts
    end
  end
end
