defmodule ResumeWeb.ResumeTemplates.Mono do
  @moduledoc """
  Mono resume template.

  Developer-focused aesthetic with monospace headings and blue accents.
  """

  use ResumeWeb, :html

  import ResumeWeb.ResumeTemplates.Helpers

  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="resume">
      <.contact_info contact={@data.contact_info} />
      <.summary_section summary={@data.summary} />
      <.work_experience_section experiences={@data.work_experience} />
      <.education_section entries={@data.education} />
      <.skills_section groups={@data.skills} />
      <.certifications_section certs={@data.certifications} />
      <.projects_section projects={@data.projects} />
      <.publications_section pubs={@data.publications} />
      <.volunteer_section entries={@data.volunteer_work} />
      <.languages_section languages={Map.get(@data, :languages, [])} />
      <.awards_section awards={Map.get(@data, :awards, [])} />
    </div>
    """
  end

  defp contact_info(%{contact: nil} = assigns), do: ~H""

  defp contact_info(assigns) do
    ~H"""
    <header class="mono-header">
      <h1 class="mono-name">{@contact.name}</h1>
      <div class="mono-contact-row">
        <span :if={@contact.email}>{@contact.email}</span>
        <span :if={@contact.phone}>{@contact.phone}</span>
        <span :if={@contact.location}>{@contact.location}</span>
        <span :if={@contact.website}>
          <a href={@contact.website}>{@contact.website}</a>
        </span>
        <span :if={@contact.linkedin}>
          <a href={@contact.linkedin}>LinkedIn</a>
        </span>
        <span :if={@contact.github}>
          <a href={@contact.github}>GitHub</a>
        </span>
      </div>
    </header>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Summary</h2>
      <p class="mono-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Experience</h2>
      <div :for={exp <- @experiences} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">{exp.role}</span>
          <span class="mono-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="mono-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="mono-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Education</h2>
      <div :for={edu <- @entries} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">{edu.degree} in {edu.field}</span>
          <span class="mono-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="mono-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Skills</h2>
      <div class="mono-skills">
        <div :for={group <- @groups} class="mono-skill-group">
          <span class="mono-skill-category">{group.category}:</span>
          <span>{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Certifications</h2>
      <div :for={cert <- @certs} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="mono-entry-meta"> —  {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="mono-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Projects</h2>
      <div :for={proj <- @projects} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="mono-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="mono-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="mono-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Publications</h2>
      <div :for={pub <- @pubs} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="mono-entry-meta"> —  {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="mono-link">Link</a>
          </span>
          <span :if={pub.date} class="mono-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Volunteer Work</h2>
      <div :for={vol <- @entries} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">{vol.role}</span>
          <span class="mono-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="mono-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="mono-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Languages</h2>
      <div class="mono-skills">
        <span :for={lang <- @languages} class="mono-language">
          {lang.name}<span :if={lang.fluency} class="mono-entry-meta"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="mono-section">
      <h2 class="mono-section-title">Awards</h2>
      <div :for={award <- @awards} class="mono-entry">
        <div class="mono-entry-header">
          <span class="mono-entry-title">
            {award.title}
            <span :if={award.issuer} class="mono-entry-meta"> —  {award.issuer}</span>
          </span>
          <span :if={award.date} class="mono-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="mono-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    .resume, .resume * {
      font-family: system-ui, -apple-system, sans-serif !important;
      color: #1a1a1a !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
      max-width: 700px;
      margin: 0 auto;
    }

    .resume a {
      color: #0066cc !important;
      text-decoration: none;
    }

    /* Header */
    .resume .mono-header {
      margin-bottom: 12pt;
      padding-bottom: 10pt;
      border-bottom: 2pt solid #0066cc;
    }

    .resume .mono-name {
      font-family: ui-monospace, "Cascadia Code", "Fira Code", monospace !important;
      font-size: 22pt;
      font-weight: 700;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #1a1a1a !important;
    }

    .resume .mono-contact-row {
      display: flex;
      flex-wrap: wrap;
      gap: 4pt 12pt;
      font-size: 9pt;
      color: #555 !important;
    }

    .resume .mono-contact-row span {
      white-space: nowrap;
    }

    .resume .mono-contact-row a {
      color: #0066cc !important;
    }

    /* Sections */
    .resume .mono-section {
      margin-top: 12pt;
    }

    .resume .mono-section-title {
      font-family: ui-monospace, "Cascadia Code", "Fira Code", monospace !important;
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1.5pt;
      border-bottom: 1.5pt solid #0066cc;
      padding-bottom: 3pt;
      margin: 0 0 8pt 0;
      color: #0066cc !important;
    }

    .resume .mono-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .mono-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .mono-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .mono-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .mono-entry-date {
      font-family: ui-monospace, "Cascadia Code", "Fira Code", monospace !important;
      font-size: 8pt;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .mono-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
    }

    .resume .mono-entry-meta {
      font-weight: 400;
      color: #555 !important;
    }

    .resume .mono-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #0066cc !important;
    }

    /* Lists — arrow bullets */
    .resume .mono-list {
      margin: 3pt 0 0 0;
      padding-left: 16pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style: none !important;
    }

    .resume .mono-list li {
      margin-bottom: 2pt;
      position: relative;
      padding-left: 2pt;
    }

    .resume .mono-list li::before {
      content: "\\2192";
      position: absolute;
      left: -14pt;
      color: #0066cc !important;
      font-family: ui-monospace, monospace !important;
      font-size: 9pt;
    }

    /* Skills */
    .resume .mono-skills {
      font-size: 9.5pt;
    }

    .resume .mono-skill-group {
      margin-bottom: 2pt;
    }

    .resume .mono-skill-category {
      font-family: ui-monospace, "Cascadia Code", "Fira Code", monospace !important;
      font-weight: 600;
      color: #0066cc !important;
    }

    /* Languages */
    .resume .mono-language + .mono-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }
    """
  end
end
