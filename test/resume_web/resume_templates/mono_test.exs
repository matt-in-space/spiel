defmodule ResumeWeb.ResumeTemplates.MonoTest do
  use ExUnit.Case, async: true

  alias ResumeWeb.ResumeTemplates.Mono

  @sample_data %Resume.Resumes.ResumeData{
    summary: "Experienced software engineer.",
    contact_info: %Resume.Resumes.ContactInfo{
      name: "Jane Doe",
      email: "jane@example.com",
      phone: "555-1234",
      location: "San Francisco, CA",
      websites: [
        %Resume.Resumes.Website{type: "custom", url: "https://jane.dev", label: "jane.dev"},
        %Resume.Resumes.Website{type: "linkedin", url: "https://linkedin.com/in/jane"},
        %Resume.Resumes.Website{type: "github", url: "https://github.com/jane"}
      ]
    },
    work_experience: [
      %Resume.Resumes.WorkExperience{
        role: "Senior Developer",
        company: "Acme Corp",
        current: true,
        start_date: %Resume.Resumes.FlexDate{year: 2020, month: 3},
        end_date: nil,
        accomplishments: ["Led team of 5", "Shipped v2.0"]
      }
    ],
    education: [
      %Resume.Resumes.Education{
        institution: "MIT",
        degree: "B.S.",
        field: "Computer Science",
        start_date: %Resume.Resumes.FlexDate{year: 2014, month: 9},
        end_date: %Resume.Resumes.FlexDate{year: 2018, month: 5}
      }
    ],
    skills: [
      %Resume.Resumes.SkillGroup{category: "Languages", skills: ["Elixir", "Rust", "TypeScript"]}
    ],
    certifications: [
      %Resume.Resumes.Certification{
        name: "AWS Solutions Architect",
        issuer: "Amazon",
        date: %Resume.Resumes.FlexDate{year: 2022, month: 6}
      }
    ],
    projects: [
      %Resume.Resumes.Project{
        name: "OpenWidget",
        description: "An open-source widget library",
        url: "https://github.com/jane/openwidget",
        highlights: ["1k stars on GitHub"]
      }
    ],
    publications: [
      %Resume.Resumes.Publication{
        title: "Distributed Systems in Practice",
        publisher: "ACM",
        url: "https://doi.org/example",
        date: %Resume.Resumes.FlexDate{year: 2021}
      }
    ],
    volunteer_work: [
      %Resume.Resumes.VolunteerWork{
        role: "Mentor",
        organization: "Code for All",
        description: "Mentored junior developers",
        start_date: %Resume.Resumes.FlexDate{year: 2019, month: 1},
        end_date: %Resume.Resumes.FlexDate{year: 2020, month: 12}
      }
    ],
    languages: [
      %Resume.Resumes.Language{name: "English", fluency: "Native"},
      %Resume.Resumes.Language{name: "Spanish", fluency: "Conversational"}
    ],
    awards: [
      %Resume.Resumes.Award{
        title: "Employee of the Year",
        issuer: "Acme Corp",
        summary: "Outstanding performance",
        date: %Resume.Resumes.FlexDate{year: 2023, month: 1}
      }
    ]
  }

  describe "render/1" do
    test "renders all sections with full data" do
      html =
        Mono.render(%{data: @sample_data})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Jane Doe"
      assert html =~ "jane@example.com"
      assert html =~ "Experienced software engineer."
      assert html =~ "Senior Developer"
      assert html =~ "Acme Corp"
      assert html =~ "Led team of 5"
      assert html =~ "B.S."
      assert html =~ "MIT"
      assert html =~ "Elixir, Rust, TypeScript"
      assert html =~ "AWS Solutions Architect"
      assert html =~ "OpenWidget"
      assert html =~ "Distributed Systems in Practice"
      assert html =~ "Mentor"
      assert html =~ "English"
      assert html =~ "Employee of the Year"
    end

    test "skips empty sections" do
      data = %Resume.Resumes.ResumeData{
        summary: nil,
        contact_info: %Resume.Resumes.ContactInfo{name: "Solo Person"},
        work_experience: [],
        education: [],
        skills: [],
        certifications: [],
        projects: [],
        publications: [],
        volunteer_work: [],
        languages: [],
        awards: []
      }

      html =
        Mono.render(%{data: data})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Solo Person"
      refute html =~ "Experience"
      refute html =~ "Education"
      refute html =~ "Skills"
      refute html =~ "Languages"
      refute html =~ "Awards"
    end
  end

  describe "css/0" do
    test "returns a CSS string with @page rule and mono styles" do
      css = Mono.css()
      assert css =~ "@page"
      assert css =~ ".resume"
      assert css =~ "monospace"
      assert css =~ "#0066cc"
    end
  end
end
