defmodule ResumeWeb.ResumeTemplates.Typewriter do
  @moduledoc """
  Typewriter resume template.

  Monospace font throughout, simulating a typed document aesthetic.
  Dashed underlines on section titles, no colors, generous line-height.
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
    <header class="tw-header">
      <h1 class="tw-name">{@contact.name}</h1>
      <div class="tw-contact-row">
        <span :if={@contact.email}>{@contact.email}</span>
        <span :if={@contact.phone}>{@contact.phone}</span>
        <span :if={@contact.location}>{@contact.location}</span>
        <span :for={w <- @contact.websites || []}>
          <a href={w.url}>{website_display(w)}</a>
        </span>
      </div>
    </header>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Summary</h2>
      <p class="tw-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Work Experience</h2>
      <div :for={exp <- @experiences} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">{exp.role}</span>
          <span class="tw-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="tw-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="tw-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Education</h2>
      <div :for={edu <- @entries} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">{edu.degree} in {edu.field}</span>
          <span class="tw-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="tw-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Skills</h2>
      <div class="tw-skills">
        <div :for={group <- @groups} class="tw-skill-group">
          <span class="tw-skill-category">{group.category}:</span>
          <span class="tw-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Certifications</h2>
      <div :for={cert <- @certs} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="tw-entry-meta">&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="tw-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Projects</h2>
      <div :for={proj <- @projects} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="tw-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="tw-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="tw-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Publications</h2>
      <div :for={pub <- @pubs} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="tw-entry-meta">&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="tw-link">Link</a>
          </span>
          <span :if={pub.date} class="tw-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Volunteer Work</h2>
      <div :for={vol <- @entries} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">{vol.role}</span>
          <span class="tw-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="tw-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="tw-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Languages</h2>
      <div class="tw-languages">
        <span :for={lang <- @languages} class="tw-language">
          {lang.name}<span :if={lang.fluency} class="tw-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="tw-section">
      <h2 class="tw-section-title">Awards</h2>
      <div :for={award <- @awards} class="tw-entry">
        <div class="tw-entry-header">
          <span class="tw-entry-title">
            {award.title}
            <span :if={award.issuer} class="tw-entry-meta">&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="tw-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="tw-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 0.85in 0.9in;
    }

    /* Root — monospace everything, black on white */
    .resume, .resume * {
      font-family: "Courier New", Courier, monospace !important;
      color: #000 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.6;
    }

    .resume a {
      color: #000 !important;
      text-decoration: underline;
    }

    /* Header */
    .resume .tw-header {
      text-align: center;
      margin-bottom: 14pt;
      padding-bottom: 10pt;
      border-bottom: 1pt solid #000;
    }

    .resume .tw-name {
      font-size: 20pt;
      font-weight: 700;
      text-transform: uppercase;
      margin: 0 0 6pt 0;
      padding: 0;
      letter-spacing: 2pt;
    }

    .resume .tw-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      gap: 4pt 14pt;
      font-size: 9pt;
    }

    .resume .tw-contact-row span {
      white-space: nowrap;
    }

    /* Sections */
    .resume .tw-section {
      margin-top: 14pt;
    }

    .resume .tw-section-title {
      font-size: 11pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1pt;
      border-bottom: 1.5pt dashed #000;
      padding-bottom: 2pt;
      margin: 0 0 8pt 0;
    }

    .resume .tw-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
    }

    /* Entries */
    .resume .tw-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .tw-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .tw-entry-title {
      font-weight: 700;
      font-size: 10pt;
    }

    .resume .tw-entry-date {
      font-size: 8.5pt;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .tw-entry-subtitle {
      font-size: 9.5pt;
    }

    .resume .tw-entry-meta {
      font-weight: 400;
    }

    .resume .tw-link {
      font-size: 8.5pt;
      margin-left: 4pt;
    }

    /* Lists — asterisk bullets for typewriter feel */
    .resume .tw-list {
      margin: 3pt 0 0 0;
      padding-left: 16pt;
      font-size: 9.5pt;
      list-style-type: "* " !important;
    }

    .resume .tw-list li {
      margin-bottom: 2pt;
      display: list-item !important;
      padding-left: 2pt;
    }

    /* Skills */
    .resume .tw-skills {
      font-size: 9.5pt;
    }

    .resume .tw-skill-group {
      margin-bottom: 2pt;
    }

    .resume .tw-skill-category {
      font-weight: 700;
    }

    .resume .tw-skill-list {
      font-weight: 400;
    }

    /* Languages */
    .resume .tw-languages {
      font-size: 9.5pt;
    }

    .resume .tw-language + .tw-language::before {
      content: "  |  ";
    }

    .resume .tw-language-fluency {
      font-weight: 400;
    }
    """
  end
end
