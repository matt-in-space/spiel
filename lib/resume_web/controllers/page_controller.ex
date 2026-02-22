defmodule ResumeWeb.PageController do
  use ResumeWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/home")
    else
      conn
      |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
      |> assign(:page_title, "Spiel — Free AI Resume Builder")
      |> assign(
        :meta_description,
        "Talk about your career and get a tailored resume for every job. Free AI resume builder with voice input and 20+ professional templates."
      )
      |> render(:home)
    end
  end

  def terms(conn, _params) do
    conn
    |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
    |> assign(:page_title, "Terms of Use")
    |> assign(
      :meta_description,
      "Terms of use for Spiel, the free AI resume builder."
    )
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
    |> assign(:page_title, "Privacy Policy")
    |> assign(
      :meta_description,
      "Privacy policy for Spiel, the free AI resume builder. Learn how we handle your data."
    )
    |> render(:privacy)
  end

  def templates(conn, _params) do
    sample_data = build_sample_data()
    templates = ResumeWeb.ResumeTemplates.template_options()

    previews =
      Map.new(templates, fn {_name, key} ->
        mod = ResumeWeb.ResumeTemplates.get(key)

        html =
          mod.render(%{data: sample_data})
          |> Phoenix.HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        css = mod.css()
        full_bleed? = key in ~w(executive sidebar)
        body_padding = if full_bleed?, do: "0", else: "0.85in"

        srcdoc = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <style>#{css}
        html { width: 8.5in; }
        body { margin: 0; padding: #{body_padding}; overflow: hidden; }
        </style>
        </head>
        <body>#{html}</body>
        </html>
        """

        {key, srcdoc}
      end)

    conn
    |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
    |> assign(:page_title, "Resume Templates — Spiel")
    |> assign(
      :meta_description,
      "Browse 20+ free professional resume templates. Pick a design and build your tailored resume in minutes with Spiel."
    )
    |> assign(:templates, templates)
    |> assign(:previews, previews)
    |> render(:templates)
  end

  defp build_sample_data do
    alias Resume.Resumes.ResumeData

    %ResumeData{}
    |> ResumeData.changeset(%{
      "summary" =>
        "Results-driven software engineer with 8+ years of experience building scalable web applications and leading cross-functional teams. Passionate about clean architecture, developer experience, and shipping products that make a difference.",
      "contact_info" => %{
        "name" => "Alex Morgan",
        "email" => "alex.morgan@example.com",
        "phone" => "(555) 123-4567",
        "location" => "San Francisco, CA",
        "websites" => []
      },
      "work_experience" => [
        %{
          "role" => "Senior Software Engineer",
          "company" => "Acme Corp",
          "current" => true,
          "start_date" => %{"year" => 2021, "month" => 3},
          "end_date" => nil,
          "accomplishments" => [
            "Led migration of monolithic Rails app to Elixir/Phoenix microservices, reducing p99 latency by 60%",
            "Mentored 4 junior engineers through structured code review and pair programming sessions",
            "Designed and implemented real-time notification system serving 500K+ daily active users"
          ]
        },
        %{
          "role" => "Software Engineer",
          "company" => "Startup Inc",
          "current" => false,
          "start_date" => %{"year" => 2017, "month" => 6},
          "end_date" => %{"year" => 2021, "month" => 2},
          "accomplishments" => [
            "Built customer-facing dashboard with React and GraphQL, increasing user engagement by 40%",
            "Implemented CI/CD pipeline that reduced deployment time from 45 minutes to under 5 minutes",
            "Collaborated with product team to ship 3 major features ahead of schedule"
          ]
        }
      ],
      "education" => [
        %{
          "institution" => "University of California, Berkeley",
          "degree" => "B.S.",
          "field" => "Computer Science",
          "start_date" => %{"year" => 2013, "month" => 8},
          "end_date" => %{"year" => 2017, "month" => 5}
        }
      ],
      "skills" => [
        %{
          "category" => "Languages",
          "skills" => ["Elixir", "TypeScript", "Python", "Ruby", "SQL"]
        },
        %{
          "category" => "Frameworks",
          "skills" => ["Phoenix", "React", "Next.js", "Rails", "Tailwind CSS"]
        },
        %{
          "category" => "Tools",
          "skills" => ["PostgreSQL", "Redis", "Docker", "AWS", "GitHub Actions"]
        }
      ],
      "certifications" => [],
      "projects" => [],
      "publications" => [],
      "volunteer_work" => [],
      "languages" => [],
      "awards" => []
    })
    |> Ecto.Changeset.apply_changes()
  end
end
