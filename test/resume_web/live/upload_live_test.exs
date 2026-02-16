defmodule ResumeWeb.UploadLiveTest do
  use ResumeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Resume.AccountsFixtures

  describe "GET /upload" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      assert {:error, redirect} = live(conn, ~p"/upload")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "renders upload page for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/upload")
      assert html =~ "Upload or Paste Text"
    end
  end

  describe "input phase" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/upload")
      %{view: view, user: user}
    end

    test "shows error when submitting empty input", %{view: view} do
      html =
        view
        |> form("form", paste: %{text: ""})
        |> render_submit()

      assert html =~ "Please upload a file or paste some text."
    end

    test "paste text advances to preview phase", %{view: view} do
      view
      |> form("form", paste: %{text: "I worked at Acme Corp for 5 years as a senior engineer."})
      |> render_submit()

      html = render(view)
      assert html =~ "Preview"
      assert html =~ "I worked at Acme Corp for 5 years as a senior engineer."
      assert html =~ "Extract Details"
    end

    test "upload .txt file advances to preview phase", %{view: view} do
      file_input =
        file_input(view, "form", :document, [
          %{
            name: "resume.txt",
            content: "Senior Engineer at Acme Corp, 2019-2024",
            type: "text/plain"
          }
        ])

      render_upload(file_input, "resume.txt")

      view
      |> form("form", paste: %{text: ""})
      |> render_submit()

      html = render(view)
      assert html =~ "Preview"
      assert html =~ "Senior Engineer at Acme Corp, 2019-2024"
    end

    test "upload .pdf file advances to preview phase", %{view: view} do
      # Minimal valid PDF with embedded text
      pdf_bytes =
        "%PDF-1.0\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj\n4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\n5 0 obj<</Length 44>>stream\nBT /F1 12 Tf 100 700 Td (Hello PDF) Tj ET\nendstream\nendobj\nxref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000266 00000 n \n0000000340 00000 n \ntrailer<</Size 6/Root 1 0 R>>\nstartxref\n434\n%%EOF\n"

      file_input =
        file_input(view, "form", :document, [
          %{
            name: "resume.pdf",
            content: pdf_bytes,
            type: "application/pdf"
          }
        ])

      render_upload(file_input, "resume.pdf")

      view
      |> form("form", paste: %{text: ""})
      |> render_submit()

      html = render(view)
      assert html =~ "Preview"
      assert html =~ "Hello PDF"
    end

    test "cancel upload removes the entry", %{view: view} do
      file_input =
        file_input(view, "form", :document, [
          %{
            name: "resume.txt",
            content: "Some content",
            type: "text/plain"
          }
        ])

      render_upload(file_input, "resume.txt")
      html = render(view)
      assert html =~ "resume.txt"

      view |> element(~s(button[phx-click="cancel_upload"])) |> render_click()
      html = render(view)
      refute html =~ "resume.txt"
    end
  end

  describe "preview phase" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/upload")

      view
      |> form("form", paste: %{text: "I led a team of 10 engineers at BigCorp."})
      |> render_submit()

      %{view: view, user: user}
    end

    test "back button returns to input", %{view: view} do
      view |> element(~s(button[phx-click="back_to_input"])) |> render_click()
      html = render(view)
      assert html =~ "Paste text"
      refute html =~ "Preview"
    end

    test "extract facts advances to review with facts", %{view: view} do
      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()

      # Wait for async LLM extraction (mock is very fast)
      Process.sleep(100)
      html = render(view)

      assert html =~ "Review Extracted Details"
      assert html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end
  end

  describe "review phase" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/upload")

      view
      |> form("form", paste: %{text: "I led a team of 10 engineers."})
      |> render_submit()

      view |> element(~s(button[phx-click="extract_facts"])) |> render_click()
      Process.sleep(100)

      %{view: view, user: user}
    end

    test "remove operation button works", %{view: view} do
      html = render(view)
      assert html =~ "Mock fact about career"

      view
      |> element(~s(button[phx-click="remove_operation"][phx-value-index="0"]))
      |> render_click()

      html = render(view)

      refute html =~ "Mock fact about career"
      assert html =~ "Mock fact about skills"
    end

    test "save applies operations to user facts and redirects", %{view: view, user: user} do
      assert render(view) =~ "Review Extracted Details"

      view |> element(~s(button[phx-click="save_facts"])) |> render_click()
      flash = assert_redirect(view, ~p"/")
      assert flash["info"] =~ "Saved 2 changes"

      updated_user = Resume.Accounts.get_user!(user.id)
      assert "Mock fact about career" in updated_user.facts
      assert "Mock fact about skills" in updated_user.facts
    end

    test "start over resets to input", %{view: view} do
      view |> element(~s(button[phx-click="start_over"])) |> render_click()
      html = render(view)
      assert html =~ "Paste text"
      refute html =~ "Review Extracted Details"
    end
  end
end
