defmodule ResumeWeb.ResumeTemplates.Sidebar do
  @moduledoc """
  Sidebar resume template.

  Two-column layout with a light gray left sidebar containing contact info,
  skills, languages, and education. Main content area holds the name header,
  summary, experience, projects, certifications, awards, publications, and
  volunteer work. Indigo accent color.
  """

  use ResumeWeb, :html

  import ResumeWeb.ResumeTemplates.Helpers

  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="resume side-layout">
      <aside class="side-sidebar">
        <.sidebar_contact contact={@data.contact_info} />
        <.sidebar_skills groups={@data.skills} />
        <.sidebar_languages languages={Map.get(@data, :languages, [])} />
        <.sidebar_education entries={@data.education} />
      </aside>
      <main class="side-main">
        <.main_header contact={@data.contact_info} />
        <.summary_section summary={@data.summary} />
        <.work_experience_section experiences={@data.work_experience} />
        <.projects_section projects={@data.projects} />
        <.certifications_section certs={@data.certifications} />
        <.awards_section awards={Map.get(@data, :awards, [])} />
        <.publications_section pubs={@data.publications} />
        <.volunteer_section entries={@data.volunteer_work} />
      </main>
    </div>
    """
  end

  # Sidebar components

  defp sidebar_contact(%{contact: nil} = assigns), do: ~H""

  defp sidebar_contact(assigns) do
    ~H"""
    <div class="side-sidebar-section" data-section="contact_info">
      <h2 class="side-sidebar-title">Contact</h2>
      <div class="side-sidebar-contact">
        <div :if={@contact.email}>{@contact.email}</div>
        <div :if={@contact.phone}>{@contact.phone}</div>
        <div :if={@contact.location}>{@contact.location}</div>
        <div :for={w <- @contact.websites || []}>
          <a href={w.url}>{website_display(w)}</a>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_skills(%{groups: []} = assigns), do: ~H""

  defp sidebar_skills(assigns) do
    ~H"""
    <div class="side-sidebar-section">
      <h2 class="side-sidebar-title">Skills</h2>
      <div
        :for={{group, idx} <- Enum.with_index(@groups)}
        data-section="skills"
        data-section-index={idx}
        class="side-sidebar-skill-group"
      >
        <div class="side-sidebar-skill-category">{group.category}</div>
        <div class="side-sidebar-skill-list">{Enum.join(group.skills, ", ")}</div>
      </div>
    </div>
    """
  end

  defp sidebar_languages(%{languages: []} = assigns), do: ~H""

  defp sidebar_languages(assigns) do
    ~H"""
    <div class="side-sidebar-section">
      <h2 class="side-sidebar-title">Languages</h2>
      <div
        :for={{lang, idx} <- Enum.with_index(@languages)}
        data-section="languages"
        data-section-index={idx}
        class="side-sidebar-language"
      >
        {lang.name}
        <span :if={lang.fluency} class="side-sidebar-lang-fluency">&nbsp;&mdash; {lang.fluency}</span>
      </div>
    </div>
    """
  end

  defp sidebar_education(%{entries: []} = assigns), do: ~H""

  defp sidebar_education(assigns) do
    ~H"""
    <div class="side-sidebar-section">
      <h2 class="side-sidebar-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="side-sidebar-edu"
      >
        <div class="side-sidebar-edu-degree">{edu.degree} in {edu.field}</div>
        <div class="side-sidebar-edu-school">{edu.institution}</div>
        <div class="side-sidebar-edu-date">
          {format_date_range(edu.start_date, edu.end_date, false)}
        </div>
      </div>
    </div>
    """
  end

  # Main content components

  defp main_header(%{contact: nil} = assigns), do: ~H""

  defp main_header(assigns) do
    ~H"""
    <header class="side-main-header" data-section="contact_info">
      <h1 class="side-name">{@contact.name}</h1>
    </header>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section class="side-section" data-section="summary">
      <h2 class="side-section-title">Summary</h2>
      <p class="side-body">{inline_format(@summary)}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">{exp.role}</span>
          <span class="side-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="side-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="side-list">
          <li :for={item <- exp.accomplishments}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="side-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="side-body">{inline_format(proj.description)}</p>
        <ul :if={proj.highlights != []} class="side-list">
          <li :for={item <- proj.highlights}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="side-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="side-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">
            {award.title}
            <span :if={award.issuer} class="side-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="side-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="side-body">{inline_format(award.summary)}</p>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="side-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="side-link">Link</a>
          </span>
          <span :if={pub.date} class="side-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="side-section">
      <h2 class="side-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="side-entry"
      >
        <div class="side-entry-header">
          <span class="side-entry-title">{vol.role}</span>
          <span class="side-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="side-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="side-body">{inline_format(vol.description)}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    #{inline_format_css()}
    @page {
      size: letter;
      margin: 0;
    }

    .resume, .resume * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #222 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.4;
      padding: 0;
    }

    .resume a {
      color: inherit !important;
      text-decoration: none;
    }

    /* Two-column layout */
    .resume.side-layout {
      display: flex;
      min-height: 100vh;
    }

    /* Sidebar */
    .resume .side-sidebar {
      width: 180pt;
      min-width: 180pt;
      background-color: #f5f5f5 !important;
      padding: 24pt 14pt;
    }

    .resume .side-sidebar,
    .resume .side-sidebar * {
      color: #333 !important;
    }

    .resume .side-sidebar a {
      color: #3F51B5 !important;
    }

    .resume .side-sidebar-section {
      margin-bottom: 14pt;
    }

    .resume .side-sidebar-title {
      font-size: 9pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1pt;
      border-bottom: 1pt solid #3F51B5;
      padding-bottom: 3pt;
      margin: 0 0 6pt 0;
      color: #3F51B5 !important;
    }

    .resume .side-sidebar-contact div {
      font-size: 8.5pt;
      margin-bottom: 3pt;
      color: #444 !important;
    }

    .resume .side-sidebar-skill-group {
      margin-bottom: 6pt;
    }

    .resume .side-sidebar-skill-category {
      font-weight: 700;
      font-size: 8.5pt;
      color: #3F51B5 !important;
    }

    .resume .side-sidebar-skill-list {
      font-size: 8.5pt;
      color: #555 !important;
    }

    .resume .side-sidebar-language {
      font-size: 8.5pt;
      margin-bottom: 2pt;
      color: #444 !important;
    }

    .resume .side-sidebar-lang-fluency {
      color: #777 !important;
    }

    .resume .side-sidebar-edu {
      margin-bottom: 8pt;
    }

    .resume .side-sidebar-edu-degree {
      font-weight: 600;
      font-size: 8.5pt;
      color: #333 !important;
    }

    .resume .side-sidebar-edu-school {
      font-size: 8pt;
      color: #555 !important;
    }

    .resume .side-sidebar-edu-date {
      font-size: 8pt;
      color: #777 !important;
    }

    /* Main content */
    .resume .side-main {
      flex: 1;
      padding: 24pt 28pt;
    }

    .resume .side-main-header {
      margin-bottom: 10pt;
      border-bottom: 2pt solid #3F51B5;
      padding-bottom: 6pt;
    }

    .resume .side-name {
      font-size: 22pt;
      font-weight: 700;
      margin: 0;
      padding: 0;
      color: #3F51B5 !important;
    }

    /* Sections */
    .resume .side-section {
      margin-top: 10pt;
    }

    .resume .side-section-title {
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.75pt;
      border-bottom: 0.75pt solid #3F51B5;
      padding-bottom: 2pt;
      margin: 0 0 6pt 0;
      color: #3F51B5 !important;
      break-after: avoid;
    }

    .resume .side-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .side-entry {
      margin-bottom: 7pt;
    }

    .resume .side-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .side-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .side-entry-date {
      font-size: 8.5pt;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .side-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
    }

    .resume .side-entry-meta {
      font-weight: 400;
      color: #555 !important;
    }

    .resume .side-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #3F51B5 !important;
    }

    /* Lists */
    .resume .side-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .side-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }
    """
  end
end
