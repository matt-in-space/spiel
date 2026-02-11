defmodule ResumeWeb.ResumePDFController do
  use ResumeWeb, :controller

  alias Resume.{PDF, Resumes}

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive
  }

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    resume = Resumes.get_user_resume!(user.id, id)
    template_mod = Map.get(@templates, resume.template, ResumeWeb.ResumeTemplates.Default)

    html =
      template_mod.render(%{data: resume.data})
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

    name =
      case resume.data do
        %{contact_info: %{name: name}} when is_binary(name) and name != "" -> name
        _ -> "Resume"
      end

    filename = sanitize_filename(name) <> " Resume.pdf"

    case PDF.render(full_html, css, filename: filename) do
      {:ok, pdf_binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
        |> send_resp(200, pdf_binary)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to generate PDF. Please try again.")
        |> redirect(to: ~p"/resumes/#{resume}")
    end
  end

  defp sanitize_filename(name) do
    name
    |> String.replace(~r/[^\w\s\-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.slice(0, 100)
  end
end
