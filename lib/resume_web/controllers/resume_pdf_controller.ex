defmodule ResumeWeb.ResumePDFController do
  use ResumeWeb, :controller

  alias Resume.{PDF, Resumes}

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive,
    "elegant" => ResumeWeb.ResumeTemplates.Elegant,
    "classic" => ResumeWeb.ResumeTemplates.Classic,
    "flat" => ResumeWeb.ResumeTemplates.Flat,
    "kendall" => ResumeWeb.ResumeTemplates.Kendall,
    "editorial" => ResumeWeb.ResumeTemplates.Editorial,
    "typewriter" => ResumeWeb.ResumeTemplates.Typewriter,
    "nordic" => ResumeWeb.ResumeTemplates.Nordic,
    "berlin" => ResumeWeb.ResumeTemplates.Berlin,
    "even" => ResumeWeb.ResumeTemplates.Even,
    "paper" => ResumeWeb.ResumeTemplates.Paper,
    "consultant" => ResumeWeb.ResumeTemplates.Consultant,
    "sidebar" => ResumeWeb.ResumeTemplates.Sidebar,
    "stackoverflow" => ResumeWeb.ResumeTemplates.Stackoverflow,
    "academic" => ResumeWeb.ResumeTemplates.Academic,
    "minimalist" => ResumeWeb.ResumeTemplates.Minimalist,
    "macchiato" => ResumeWeb.ResumeTemplates.Macchiato
  }

  def show(conn, %{"id" => id} = params) do
    user = conn.assigns.current_scope.user
    resume = Resumes.get_user_resume!(user.id, id)

    version =
      case params["v"] do
        nil -> Resumes.get_latest_version!(resume.id)
        v -> Resumes.get_version!(resume.id, String.to_integer(v))
      end

    data = Resumes.dump_version_data(version)
    template_mod = Map.get(@templates, resume.template, ResumeWeb.ResumeTemplates.Default)

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
      case data do
        %{contact_info: %{name: name}} when is_binary(name) and name != "" -> name
        _ -> nil
      end

    filename =
      [person_name, resume.title]
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join(" - ", &sanitize_filename/1)
      |> Kernel.<>(" Resume.pdf")

    case PDF.render(full_html, css, filename: filename) do
      {:ok, pdf_binary} ->
        Resumes.increment_download_count(resume)

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
