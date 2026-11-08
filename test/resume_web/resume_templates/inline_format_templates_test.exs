defmodule ResumeWeb.ResumeTemplates.InlineFormatTemplatesTest do
  use ExUnit.Case, async: true

  alias Resume.Resumes

  @data %Resumes.ResumeData{
    summary: "Engineer with *deep* **Elixir** experience",
    contact_info: %Resumes.ContactInfo{name: "Jane Doe"},
    work_experience: [
      %Resumes.WorkExperience{
        role: "Developer",
        company: "Acme",
        start_date: %Resumes.FlexDate{year: 2020},
        accomplishments: ["Built it with **React** and <b>Rails</b>"]
      }
    ],
    projects: [
      %Resumes.Project{
        name: "Tool",
        description: "A ==fast== CLI",
        highlights: ["Used by **10k** devs"]
      }
    ]
  }

  for {key, mod} <- ResumeWeb.ResumeTemplates.templates() do
    @mod mod
    test "#{key} renders inline formatting and escapes raw HTML" do
      html = @mod.render(%{data: @data}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

      assert html =~ "<strong>React</strong>"
      assert html =~ "<strong>Elixir</strong>"
      assert html =~ "<em>deep</em>"
      assert html =~ "<mark>fast</mark>"
      assert html =~ "<strong>10k</strong>"
      assert html =~ "&lt;b&gt;Rails&lt;/b&gt;"
      assert @mod.css() =~ ".resume mark"
    end
  end

  for {_name, key} <- ResumeWeb.CoverLetterTemplates.template_options() do
    @key key
    test "cover letter #{key} renders inline formatting" do
      mod = ResumeWeb.CoverLetterTemplates.get(@key)

      data = %{
        greeting: "Dear Hiring Manager,",
        opening: "I am **excited**",
        body: ["I know *Elixir*"],
        closing: "==Thanks==",
        signature: "Jane"
      }

      html = mod.render(%{data: data}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
      assert html =~ "<strong>excited</strong>"
      assert html =~ "<em>Elixir</em>"
      assert html =~ "<mark>Thanks</mark>"
    end
  end
end
