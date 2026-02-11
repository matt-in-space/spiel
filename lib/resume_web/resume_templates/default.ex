defmodule ResumeWeb.ResumeTemplates.Default do
  @moduledoc """
  Default resume template.

  Renders a clean, single-column resume using semantic CSS classes.
  Designed to work both as a LiveView preview (with `<style>` injection)
  and as a standalone HTML document for PDF generation via WeasyPrint.
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
    <header class="resume-header">
      <h1 class="resume-name">{@contact.name}</h1>
      <div class="resume-contact-details">
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
    <section class="resume-section">
      <h2 class="resume-section-title">Summary</h2>
      <p class="resume-summary">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Work Experience</h2>
      <div :for={exp <- @experiences} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">{exp.role}</span>
          <span class="resume-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="resume-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="resume-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Education</h2>
      <div :for={edu <- @entries} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">{edu.degree} in {edu.field}</span>
          <span class="resume-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="resume-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Skills</h2>
      <div class="resume-skills">
        <div :for={group <- @groups} class="resume-skill-group">
          <span class="resume-skill-category">{group.category}:</span>
          <span class="resume-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Certifications</h2>
      <div :for={cert <- @certs} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="resume-entry-issuer"> —    {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="resume-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Projects</h2>
      <div :for={proj <- @projects} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="resume-entry-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="resume-entry-description">{proj.description}</p>
        <ul :if={proj.highlights != []} class="resume-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Publications</h2>
      <div :for={pub <- @pubs} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="resume-entry-issuer"> —    {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="resume-entry-link">Link</a>
          </span>
          <span :if={pub.date} class="resume-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Volunteer Work</h2>
      <div :for={vol <- @entries} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">{vol.role}</span>
          <span class="resume-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="resume-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="resume-entry-description">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Languages</h2>
      <div class="resume-skills">
        <span :for={lang <- @languages} class="resume-language">
          {lang.name}<span :if={lang.fluency} class="resume-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="resume-section">
      <h2 class="resume-section-title">Awards</h2>
      <div :for={award <- @awards} class="resume-entry">
        <div class="resume-entry-header">
          <span class="resume-entry-title">
            {award.title}
            <span :if={award.issuer} class="resume-entry-issuer"> —  {award.issuer}</span>
          </span>
          <span :if={award.date} class="resume-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="resume-entry-description">{award.summary}</p>
      </div>
    </section>
    """
  end

  @doc """
  Returns the CSS string for this template.

  Uses semantic classes scoped under `.resume` so it can be injected
  via `<style>` without conflicting with Tailwind on the page.
  """
  def css do
    """
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    /* Root — must override daisyUI theme colors and Tailwind resets */
    .resume, .resume * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #222 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.4;
    }

    .resume a {
      color: inherit !important;
      text-decoration: none;
    }

    /* Header */
    .resume .resume-header {
      text-align: center;
      margin-bottom: 10pt;
      padding-bottom: 8pt;
      border-bottom: 1.5pt solid #333;
    }

    .resume .resume-name {
      font-size: 20pt;
      font-weight: 700;
      margin: 0 0 4pt 0;
      padding: 0;
      letter-spacing: 0.5pt;
    }

    .resume .resume-contact-details,
    .resume .resume-contact-details * {
      font-size: 9pt;
      color: #444 !important;
    }

    .resume .resume-contact-details span {
      white-space: nowrap;
    }

    .resume .resume-contact-details span + span::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    /* Sections */
    .resume .resume-section {
      margin-top: 10pt;
    }

    .resume .resume-section-title {
      font-size: 11pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.75pt;
      border-bottom: 0.75pt solid #999;
      padding-bottom: 2pt;
      margin: 0 0 6pt 0;
    }

    .resume .resume-summary {
      margin: 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .resume-entry {
      margin-bottom: 6pt;
      break-inside: avoid;
    }

    .resume .resume-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .resume-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .resume-entry-date {
      font-size: 8.5pt;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .resume-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
    }

    .resume .resume-entry-issuer {
      font-weight: 400;
      color: #555 !important;
    }

    .resume .resume-entry-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #555 !important;
    }

    .resume .resume-entry-description {
      font-size: 9.5pt;
      color: #333 !important;
      margin: 2pt 0 0 0;
    }

    /* Lists — override Tailwind Preflight reset */
    .resume .resume-list {
      margin: 2pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .resume-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .resume-skills {
      font-size: 9.5pt;
    }

    .resume .resume-skill-group {
      margin-bottom: 2pt;
    }

    .resume .resume-skill-category {
      font-weight: 600;
    }

    .resume .resume-skill-list {
      color: #333 !important;
    }

    /* Languages */
    .resume .resume-language + .resume-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .resume-language-fluency {
      font-weight: 400;
      color: #555 !important;
    }
    """
  end
end
