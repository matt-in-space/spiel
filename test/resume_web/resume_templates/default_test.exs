defmodule ResumeWeb.ResumeTemplates.DefaultTest do
  use ExUnit.Case, async: true

  alias ResumeWeb.ResumeTemplates.Default
  alias ResumeWeb.ResumeTemplates.Helpers

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
        Default.render(%{data: @sample_data})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Jane Doe"
      assert html =~ "jane@example.com"
      assert html =~ "555-1234"
      assert html =~ "San Francisco, CA"
      assert html =~ "Experienced software engineer."
      assert html =~ "Senior Developer"
      assert html =~ "Acme Corp"
      assert html =~ "Led team of 5"
      assert html =~ "Mar 2020"
      assert html =~ "Present"
      assert html =~ "B.S."
      assert html =~ "Computer Science"
      assert html =~ "MIT"
      assert html =~ "Elixir, Rust, TypeScript"
      assert html =~ "AWS Solutions Architect"
      assert html =~ "Amazon"
      assert html =~ "OpenWidget"
      assert html =~ "An open-source widget library"
      assert html =~ "1k stars on GitHub"
      assert html =~ "Distributed Systems in Practice"
      assert html =~ "ACM"
      assert html =~ "Mentor"
      assert html =~ "Code for All"
      assert html =~ "English"
      assert html =~ "Native"
      assert html =~ "Spanish"
      assert html =~ "Employee of the Year"
      assert html =~ "Acme Corp"
      assert html =~ "Outstanding performance"
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
        Default.render(%{data: data})
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()

      assert html =~ "Solo Person"
      refute html =~ "Work Experience"
      refute html =~ "Education"
      refute html =~ "Skills"
      refute html =~ "Summary"
      refute html =~ "Languages"
      refute html =~ "Awards"
    end
  end

  describe "css/0" do
    test "returns a CSS string with @page rule" do
      css = Default.css()
      assert css =~ "@page"
      assert css =~ ".resume"
      assert css =~ "break-inside: avoid"
    end
  end

  describe "format_flex_date/1" do
    test "formats year and month" do
      assert Helpers.format_flex_date(%{year: 2023, month: 11}) == "Nov 2023"
    end

    test "formats year only" do
      assert Helpers.format_flex_date(%{year: 2023, month: nil}) == "2023"
    end

    test "handles nil" do
      assert Helpers.format_flex_date(nil) == ""
    end
  end

  describe "format_date_range/3" do
    test "formats full range" do
      s = %{year: 2020, month: 1}
      e = %{year: 2023, month: 6}
      assert Helpers.format_date_range(s, e, false) == "Jan 2020 — Jun 2023"
    end

    test "current shows Present" do
      s = %{year: 2020, month: 1}
      assert Helpers.format_date_range(s, nil, true) == "Jan 2020 — Present"
    end

    test "nil start and end" do
      assert Helpers.format_date_range(nil, nil, false) == ""
    end
  end
end
