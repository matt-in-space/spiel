defmodule Resume.JobPostingsTest do
  use ExUnit.Case, async: true

  alias Resume.JobPostings

  describe "fetch_text/2" do
    test "extracts text from HTML response" do
      html = """
      <html>
        <head><title>Job</title></head>
        <body>
          <nav>Navigation stuff</nav>
          <script>var x = 1;</script>
          <style>.foo { color: red; }</style>
          <div>
            <h1>Senior Elixir Developer</h1>
            <p>We are looking for an experienced developer.</p>
            <ul>
              <li>5+ years of Elixir</li>
              <li>Phoenix LiveView experience</li>
            </ul>
          </div>
          <footer>Footer content</footer>
        </body>
      </html>
      """

      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, html)
      end)

      assert {:ok, text} =
               JobPostings.fetch_text("http://example.com/job", plug: {Req.Test, JobPostings})

      assert text =~ "Senior Elixir Developer"
      assert text =~ "experienced developer"
      assert text =~ "5+ years of Elixir"
      assert text =~ "Phoenix LiveView experience"
      refute text =~ "Navigation stuff"
      refute text =~ "Footer content"
      refute text =~ "var x = 1"
      refute text =~ ".foo"
    end

    test "returns error on non-200 status" do
      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
      end)

      assert {:error, {:http_status, 404}} =
               JobPostings.fetch_text("http://example.com/job", plug: {Req.Test, JobPostings})
    end

    test "decodes HTML entities" do
      html =
        "<div><h1>Ruby &amp; Rails Developer</h1><p>We need someone who loves Ruby &amp; Rails &lt;3 and has 5+ years of experience building web applications.</p></div>"

      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, html)
      end)

      assert {:ok, text} =
               JobPostings.fetch_text("http://example.com/job", plug: {Req.Test, JobPostings})

      assert text =~ "Ruby & Rails"
      assert text =~ "<3"
    end

    test "rejects gate pages that require JavaScript or login" do
      for html <- [
            "<html><body><p>JavaScript must be enabled to use this application.</p></body></html>",
            "<html><body><p>Please sign in to view this page.</p></body></html>",
            "<html><body><p>Checking your browser before accessing the site.</p></body></html>"
          ] do
        Req.Test.stub(JobPostings, fn conn ->
          Plug.Conn.send_resp(conn, 200, html)
        end)

        assert {:error, :unusable_content} =
                 JobPostings.fetch_text("http://example.com/job", plug: {Req.Test, JobPostings})
      end
    end

    test "rejects pages with too little content" do
      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, "<p>Error</p>")
      end)

      assert {:error, :unusable_content} =
               JobPostings.fetch_text("http://example.com/job", plug: {Req.Test, JobPostings})
    end
  end

  describe "ATS API sniffing" do
    test "Greenhouse URL extracts content from API" do
      job_html =
        "<p>We are looking for a Senior Engineer to join our team and build amazing products with Elixir and Phoenix.</p>"

      Req.Test.stub(JobPostings, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"content" => job_html}))
      end)

      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://boards.greenhouse.io/acme/jobs/12345",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Senior Engineer"
      assert text =~ "Elixir and Phoenix"
    end

    test "Greenhouse URL works with job-boards subdomain" do
      job_html =
        "<p>We are looking for a Senior Engineer to join our team and build amazing products with Elixir and Phoenix.</p>"

      Req.Test.stub(JobPostings, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"content" => job_html}))
      end)

      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://job-boards.greenhouse.io/acme/jobs/12345",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Senior Engineer"
    end

    test "Lever URL extracts content from API" do
      Req.Test.stub(JobPostings, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "descriptionPlain" =>
              "We are looking for a Senior Engineer to join our team and build amazing products with Elixir and Phoenix."
          })
        )
      end)

      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://jobs.lever.co/acme/abc-123",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Senior Engineer"
      assert text =~ "Elixir and Phoenix"
    end

    test "non-ATS URLs fall back to HTML scraping" do
      html =
        "<div><h1>Software Engineer</h1><p>Join our team and work on exciting projects with modern technologies and great people.</p></div>"

      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, html)
      end)

      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://careers.example.com/jobs/123",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Software Engineer"
    end

    test "Greenhouse API error falls back to HTML scraping" do
      html =
        "<div><h1>Software Engineer</h1><p>Join our team and work on exciting projects with modern technologies and great people.</p></div>"

      call_count = :counters.new(1, [:atomics])

      Req.Test.stub(JobPostings, fn conn ->
        :counters.add(call_count, 1, 1)

        if :counters.get(call_count, 1) == 1 do
          # First call (API) returns error
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(404, Jason.encode!(%{"error" => "not found"}))
        else
          # Second call (HTML fallback)
          Plug.Conn.send_resp(conn, 200, html)
        end
      end)

      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://boards.greenhouse.io/acme/jobs/99999",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Software Engineer"
    end

    test "malformed Greenhouse URL falls back to HTML scraping" do
      html =
        "<div><h1>Software Engineer</h1><p>Join our team and work on exciting projects with modern technologies and great people.</p></div>"

      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, html)
      end)

      # Missing /jobs/ segment — not a valid Greenhouse job URL pattern
      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://boards.greenhouse.io/acme/about",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Software Engineer"
    end

    test "malformed Lever URL falls back to HTML scraping" do
      html =
        "<div><h1>Software Engineer</h1><p>Join our team and work on exciting projects with modern technologies and great people.</p></div>"

      Req.Test.stub(JobPostings, fn conn ->
        Plug.Conn.send_resp(conn, 200, html)
      end)

      # Only one path segment — not a valid Lever posting URL
      assert {:ok, text} =
               JobPostings.fetch_text(
                 "https://jobs.lever.co/acme",
                 plug: {Req.Test, JobPostings}
               )

      assert text =~ "Software Engineer"
    end
  end
end
