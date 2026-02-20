defmodule ResumeWeb.ResumeTemplates.Kendall do
  @moduledoc """
  Kendall resume template.

  Compact, dense layout optimized for fitting more content. Small font sizes,
  tight spacing, left-aligned header, dark navy accents, and minimal chrome.
  Skills displayed inline as comma-separated values.
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
    <header class="kendall-header">
      <h1 class="kendall-name">{@contact.name}</h1>
      <div class="kendall-contact-details">
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
    <section class="kendall-section">
      <h2 class="kendall-section-title">Summary</h2>
      <p class="kendall-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Experience</h2>
      <div :for={exp <- @experiences} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {exp.role}<span class="kendall-entry-sep">, </span>
            <span class="kendall-entry-subtitle">
              {exp.company}
            </span>
          </span>
          <span class="kendall-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <ul :if={exp.accomplishments != []} class="kendall-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Education</h2>
      <div :for={edu <- @entries} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {edu.degree} in {edu.field}<span class="kendall-entry-sep">, </span>
            <span class="kendall-entry-subtitle">
              {edu.institution}
            </span>
          </span>
          <span class="kendall-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Skills</h2>
      <div class="kendall-skills-inline">
        <span :for={group <- @groups} class="kendall-skill-group">
          <span class="kendall-skill-category">{group.category}:</span>
          {Enum.join(group.skills, ", ")}
        </span>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Certifications</h2>
      <div :for={cert <- @certs} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="kendall-entry-issuer">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="kendall-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Projects</h2>
      <div :for={proj <- @projects} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="kendall-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="kendall-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="kendall-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Publications</h2>
      <div :for={pub <- @pubs} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="kendall-entry-issuer">
              &nbsp;&mdash; {pub.publisher}
            </span>
            <a :if={pub.url} href={pub.url} class="kendall-link">Link</a>
          </span>
          <span :if={pub.date} class="kendall-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Volunteer Work</h2>
      <div :for={vol <- @entries} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {vol.role}<span class="kendall-entry-sep">, </span>
            <span class="kendall-entry-subtitle">
              {vol.organization}
            </span>
          </span>
          <span class="kendall-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <p :if={vol.description} class="kendall-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Languages</h2>
      <div class="kendall-skills-inline">
        <span :for={lang <- @languages} class="kendall-language">
          {lang.name}<span :if={lang.fluency} class="kendall-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="kendall-section">
      <h2 class="kendall-section-title">Awards</h2>
      <div :for={award <- @awards} class="kendall-entry">
        <div class="kendall-entry-header">
          <span class="kendall-entry-title">
            {award.title}
            <span :if={award.issuer} class="kendall-entry-issuer">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="kendall-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="kendall-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  @doc """
  Returns the CSS string for the Kendall template.

  Compact dense layout with small fonts, tight spacing, and dark navy accents.
  """
  def css do
    """
    @page {
      size: letter;
      margin: 0.5in 0.6in;
    }

    /* Root — compact sans-serif */
    .resume, .resume * {
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif !important;
      color: #1a1a1a !important;
    }

    .resume {
      font-size: 9pt;
      line-height: 1.3;
    }

    .resume a {
      color: #1a237e !important;
      text-decoration: none;
    }

    /* Header — left-aligned, compact */
    .resume .kendall-header {
      margin-bottom: 6pt;
      padding-bottom: 4pt;
      border-bottom: 1.5pt solid #1a237e;
    }

    .resume .kendall-name {
      font-size: 16pt;
      font-weight: 700;
      margin: 0 0 2pt 0;
      padding: 0;
      color: #1a237e !important;
    }

    .resume .kendall-contact-details,
    .resume .kendall-contact-details * {
      font-size: 8pt;
      color: #444 !important;
    }

    .resume .kendall-contact-details span {
      white-space: nowrap;
    }

    .resume .kendall-contact-details span + span::before {
      content: " | ";
      color: #999 !important;
    }

    .resume .kendall-contact-details a {
      color: #1a237e !important;
    }

    /* Sections — tight spacing */
    .resume .kendall-section {
      margin-top: 6pt;
    }

    .resume .kendall-section-title {
      font-size: 9pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.75pt;
      color: #1a237e !important;
      border-bottom: 0.5pt solid #1a237e;
      padding-bottom: 1pt;
      margin: 0 0 3pt 0;
    }

    .resume .kendall-body {
      margin: 1pt 0 0 0;
      font-size: 8.5pt;
      color: #333 !important;
    }

    /* Entries — minimal spacing */
    .resume .kendall-entry {
      margin-bottom: 4pt;
      break-inside: avoid;
    }

    .resume .kendall-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .kendall-entry-title {
      font-weight: 600;
      font-size: 9pt;
      color: #1a1a1a !important;
    }

    .resume .kendall-entry-sep {
      font-weight: 400;
      color: #1a1a1a !important;
    }

    .resume .kendall-entry-subtitle {
      font-weight: 400;
      font-size: 9pt;
      color: #444 !important;
    }

    .resume .kendall-entry-date {
      font-size: 8pt;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 6pt;
    }

    .resume .kendall-entry-issuer {
      font-weight: 400;
      font-size: 8.5pt;
      color: #555 !important;
    }

    .resume .kendall-link {
      font-size: 8pt;
      margin-left: 3pt;
      color: #1a237e !important;
    }

    /* Lists — tight */
    .resume .kendall-list {
      margin: 1pt 0 0 0;
      padding-left: 12pt;
      font-size: 8.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .kendall-list li {
      margin-bottom: 0;
      display: list-item !important;
    }

    /* Skills — inline comma-separated */
    .resume .kendall-skills-inline {
      font-size: 8.5pt;
    }

    .resume .kendall-skill-group + .kendall-skill-group::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .kendall-skill-category {
      font-weight: 600;
      color: #1a237e !important;
    }

    /* Languages — inline */
    .resume .kendall-language + .kendall-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .kendall-language-fluency {
      font-weight: 400;
      color: #666 !important;
    }
    """
  end
end
