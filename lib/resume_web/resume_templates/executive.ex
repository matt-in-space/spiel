defmodule ResumeWeb.ResumeTemplates.Executive do
  @moduledoc """
  Executive resume template.

  Professional two-column layout with dark sidebar and serif headings.
  """

  use ResumeWeb, :html

  import ResumeWeb.ResumeTemplates.Helpers

  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="resume exec-layout">
      <aside class="exec-sidebar">
        <.sidebar_contact contact={@data.contact_info} />
        <.sidebar_skills groups={@data.skills} />
        <.sidebar_education entries={@data.education} />
        <.sidebar_languages languages={Map.get(@data, :languages, [])} />
      </aside>
      <main class="exec-main">
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
    <div class="exec-sidebar-section">
      <h2 class="exec-sidebar-title">Contact</h2>
      <div class="exec-sidebar-contact">
        <div :if={@contact.email}>{@contact.email}</div>
        <div :if={@contact.phone}>{@contact.phone}</div>
        <div :if={@contact.location}>{@contact.location}</div>
        <div :if={@contact.website}>
          <a href={@contact.website}>{@contact.website}</a>
        </div>
        <div :if={@contact.linkedin}>
          <a href={@contact.linkedin}>LinkedIn</a>
        </div>
        <div :if={@contact.github}>
          <a href={@contact.github}>GitHub</a>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_skills(%{groups: []} = assigns), do: ~H""

  defp sidebar_skills(assigns) do
    ~H"""
    <div class="exec-sidebar-section">
      <h2 class="exec-sidebar-title">Skills</h2>
      <div :for={group <- @groups} class="exec-sidebar-skill-group">
        <div class="exec-sidebar-skill-category">{group.category}</div>
        <div class="exec-sidebar-skill-list">{Enum.join(group.skills, ", ")}</div>
      </div>
    </div>
    """
  end

  defp sidebar_education(%{entries: []} = assigns), do: ~H""

  defp sidebar_education(assigns) do
    ~H"""
    <div class="exec-sidebar-section">
      <h2 class="exec-sidebar-title">Education</h2>
      <div :for={edu <- @entries} class="exec-sidebar-edu">
        <div class="exec-sidebar-edu-degree">{edu.degree} in {edu.field}</div>
        <div class="exec-sidebar-edu-school">{edu.institution}</div>
        <div class="exec-sidebar-edu-date">
          {format_date_range(edu.start_date, edu.end_date, false)}
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_languages(%{languages: []} = assigns), do: ~H""

  defp sidebar_languages(assigns) do
    ~H"""
    <div class="exec-sidebar-section">
      <h2 class="exec-sidebar-title">Languages</h2>
      <div :for={lang <- @languages} class="exec-sidebar-language">
        {lang.name}
        <span :if={lang.fluency} class="exec-sidebar-lang-fluency"> —   {lang.fluency}</span>
      </div>
    </div>
    """
  end

  # Main content components

  defp main_header(%{contact: nil} = assigns), do: ~H""

  defp main_header(assigns) do
    ~H"""
    <header class="exec-main-header">
      <h1 class="exec-name">{@contact.name}</h1>
    </header>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Professional Summary</h2>
      <p class="exec-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Experience</h2>
      <div :for={exp <- @experiences} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">{exp.role}</span>
          <span class="exec-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="exec-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="exec-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Projects</h2>
      <div :for={proj <- @projects} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="exec-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="exec-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="exec-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Certifications</h2>
      <div :for={cert <- @certs} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="exec-entry-meta"> —   {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="exec-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Awards</h2>
      <div :for={award <- @awards} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">
            {award.title}
            <span :if={award.issuer} class="exec-entry-meta"> —   {award.issuer}</span>
          </span>
          <span :if={award.date} class="exec-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="exec-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Publications</h2>
      <div :for={pub <- @pubs} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="exec-entry-meta"> —   {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="exec-link">Link</a>
          </span>
          <span :if={pub.date} class="exec-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="exec-section">
      <h2 class="exec-section-title">Volunteer Work</h2>
      <div :for={vol <- @entries} class="exec-entry">
        <div class="exec-entry-header">
          <span class="exec-entry-title">{vol.role}</span>
          <span class="exec-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="exec-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="exec-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 0;
    }

    .resume, .resume * {
      font-family: system-ui, -apple-system, sans-serif !important;
      color: #1e293b !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.4;
    }

    .resume a {
      color: inherit !important;
      text-decoration: none;
    }

    /* Two-column layout */
    .resume.exec-layout {
      display: flex;
      min-height: 100vh;
    }

    /* Sidebar */
    .resume .exec-sidebar {
      width: 200pt;
      min-width: 200pt;
      background-color: #475569 !important;
      padding: 24pt 16pt;
    }

    .resume .exec-sidebar,
    .resume .exec-sidebar * {
      color: #f1f5f9 !important;
    }

    .resume .exec-sidebar a {
      color: #cbd5e1 !important;
    }

    .resume .exec-sidebar-section {
      margin-bottom: 16pt;
    }

    .resume .exec-sidebar-title {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1pt;
      border-bottom: 1pt solid #94a3b8;
      padding-bottom: 3pt;
      margin: 0 0 8pt 0;
      color: #f1f5f9 !important;
    }

    .resume .exec-sidebar-contact div {
      font-size: 8.5pt;
      margin-bottom: 3pt;
      color: #cbd5e1 !important;
    }

    .resume .exec-sidebar-skill-group {
      margin-bottom: 6pt;
    }

    .resume .exec-sidebar-skill-category {
      font-weight: 700;
      font-size: 9pt;
      color: #f1f5f9 !important;
    }

    .resume .exec-sidebar-skill-list {
      font-size: 8.5pt;
      color: #cbd5e1 !important;
    }

    .resume .exec-sidebar-edu {
      margin-bottom: 8pt;
    }

    .resume .exec-sidebar-edu-degree {
      font-weight: 600;
      font-size: 9pt;
      color: #f1f5f9 !important;
    }

    .resume .exec-sidebar-edu-school {
      font-size: 8.5pt;
      color: #cbd5e1 !important;
    }

    .resume .exec-sidebar-edu-date {
      font-size: 8pt;
      color: #94a3b8 !important;
    }

    .resume .exec-sidebar-language {
      font-size: 9pt;
      margin-bottom: 2pt;
      color: #cbd5e1 !important;
    }

    .resume .exec-sidebar-lang-fluency {
      color: #94a3b8 !important;
    }

    /* Main content */
    .resume .exec-main {
      flex: 1;
      padding: 24pt 28pt;
    }

    .resume .exec-main-header {
      margin-bottom: 12pt;
      border-bottom: 2pt solid #475569;
      padding-bottom: 8pt;
    }

    .resume .exec-name {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 24pt;
      font-weight: 700;
      margin: 0;
      padding: 0;
      color: #1e293b !important;
    }

    /* Sections */
    .resume .exec-section {
      margin-top: 12pt;
    }

    .resume .exec-section-title {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 11pt;
      font-weight: 700;
      border-bottom: 0.75pt solid #cbd5e1;
      padding-bottom: 2pt;
      margin: 0 0 6pt 0;
      color: #334155 !important;
    }

    .resume .exec-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #334155 !important;
    }

    /* Entries */
    .resume .exec-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .exec-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .exec-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .exec-entry-date {
      font-size: 8.5pt;
      color: #64748b !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .exec-entry-subtitle {
      font-size: 9.5pt;
      color: #64748b !important;
    }

    .resume .exec-entry-meta {
      font-weight: 400;
      color: #64748b !important;
    }

    .resume .exec-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #64748b !important;
    }

    /* Lists */
    .resume .exec-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #334155 !important;
      list-style-type: disc !important;
    }

    .resume .exec-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }
    """
  end
end
