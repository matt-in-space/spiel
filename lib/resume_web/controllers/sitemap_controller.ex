defmodule ResumeWeb.SitemapController do
  use ResumeWeb, :controller

  @pages [
    %{loc: "/", priority: "1.0", changefreq: "weekly"},
    %{loc: "/templates", priority: "0.8", changefreq: "weekly"},
    %{loc: "/terms", priority: "0.3", changefreq: "monthly"},
    %{loc: "/privacy", priority: "0.3", changefreq: "monthly"}
  ]

  def index(conn, _params) do
    base_url = ResumeWeb.Endpoint.url()

    urls =
      Enum.map_join(@pages, "\n", fn page ->
        """
          <url>
            <loc>#{base_url}#{page.loc}</loc>
            <changefreq>#{page.changefreq}</changefreq>
            <priority>#{page.priority}</priority>
          </url>\
        """
      end)

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{urls}
    </urlset>
    """

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end
end
