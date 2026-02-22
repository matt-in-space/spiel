defmodule ResumeWeb.CoverLetterPDFController do
  use ResumeWeb, :controller

  alias Resume.{CoverLetters, PDF, Resumes}

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    resume = Resumes.get_user_resume!(user.id, id)
    cover_letter = CoverLetters.get_by_resume(resume.id)

    if is_nil(cover_letter) do
      conn
      |> put_flash(:error, "No cover letter found.")
      |> redirect(to: ~p"/resumes/#{resume}/cover-letter")
    else
      data = CoverLetters.dump_content(cover_letter)
      template_mod = ResumeWeb.CoverLetterTemplates.get(cover_letter.template)

      html =
        template_mod.render(%{data: data})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      css = template_mod.css()

      full_html = """
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>#{css}</style>
      </head>
      <body>#{html}</body>
      </html>
      """

      person_name =
        case user.default_resume_data do
          %{"name" => name} when is_binary(name) and name != "" -> name
          _ -> nil
        end

      filename =
        [person_name, resume.title]
        |> Enum.reject(&is_nil/1)
        |> Enum.map_join(" - ", &sanitize_filename/1)
        |> Kernel.<>(" Cover Letter.pdf")

      case PDF.render(full_html, css, filename: filename) do
        {:ok, pdf_binary} ->
          conn
          |> put_resp_content_type("application/pdf")
          |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
          |> send_resp(200, pdf_binary)

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Failed to generate PDF. Please try again.")
          |> redirect(to: ~p"/resumes/#{resume}/cover-letter")
      end
    end
  end

  defp sanitize_filename(name) do
    name
    |> String.replace(~r/[^\w\s\-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.slice(0, 100)
  end
end
