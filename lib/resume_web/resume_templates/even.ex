defmodule ResumeWeb.ResumeTemplates.Even do
  @moduledoc """
  Even resume template.

  Perfectly balanced, symmetric layout with centered header, evenly spaced
  sections, medium gray accents, and section titles framed by thin lines
  above and below.
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
    <header data-section="contact_info" class="even-header">
      <h1 class="even-name">{@contact.name}</h1>
      <div class="even-contact-row">
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
    <section data-section="summary" class="even-section">
      <h2 class="even-section-title">Summary</h2>
      <p class="even-body">{inline_format(@summary)}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Work Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">{exp.role}</span>
          <span class="even-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="even-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="even-list">
          <li :for={item <- exp.accomplishments}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">{edu.degree} in {edu.field}</span>
          <span class="even-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="even-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Skills</h2>
      <div class="even-skills-grid">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="even-skill-group"
        >
          <span class="even-skill-category">{group.category}</span>
          <span class="even-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="even-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="even-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="even-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="even-body">{inline_format(proj.description)}</p>
        <ul :if={proj.highlights != []} class="even-list">
          <li :for={item <- proj.highlights}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="even-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="even-link">Link</a>
          </span>
          <span :if={pub.date} class="even-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">{vol.role}</span>
          <span class="even-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="even-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="even-body">{inline_format(vol.description)}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Languages</h2>
      <div class="even-languages">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="even-language"
        >
          {lang.name}<span :if={lang.fluency} class="even-lang-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="even-section">
      <h2 class="even-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="even-entry"
      >
        <div class="even-entry-header">
          <span class="even-entry-title">
            {award.title}
            <span :if={award.issuer} class="even-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="even-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="even-body">{inline_format(award.summary)}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    #{inline_format_css()}
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    .resume, .resume * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #333 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
    }

    .resume a {
      color: inherit !important;
      text-decoration: none;
    }

    /* Header — centered, symmetric */
    .resume .even-header {
      text-align: center;
      margin-bottom: 14pt;
      padding-bottom: 10pt;
      border-bottom: 0.75pt solid #607D8B;
    }

    .resume .even-name {
      font-size: 22pt;
      font-weight: 700;
      margin: 0 0 6pt 0;
      padding: 0;
      letter-spacing: 1pt;
      color: #333 !important;
    }

    .resume .even-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #555 !important;
      margin: 0 -6pt;
    }

    .resume .even-contact-row,
    .resume .even-contact-row * {
      color: #555 !important;
    }

    .resume .even-contact-row span {
      white-space: nowrap;
      margin: 2pt 6pt;
    }

    /* Sections — equal spacing */
    .resume .even-section {
      margin-top: 12pt;
    }

    .resume .even-section-title {
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1pt;
      text-align: center;
      border-top: 0.75pt solid #607D8B;
      border-bottom: 0.75pt solid #607D8B;
      padding: 3pt 0;
      margin: 0 0 8pt 0;
      color: #607D8B !important;
      break-after: avoid;
    }

    .resume .even-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #444 !important;
    }

    /* Entries */
    .resume .even-entry {
      margin-bottom: 7pt;
    }

    .resume .even-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .even-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .even-entry-date {
      font-size: 8.5pt;
      color: #777 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .even-entry-subtitle {
      font-size: 9.5pt;
      color: #666 !important;
    }

    .resume .even-entry-meta {
      font-weight: 400;
      color: #666 !important;
    }

    .resume .even-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #607D8B !important;
    }

    /* Lists */
    .resume .even-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #444 !important;
      list-style-type: disc !important;
    }

    .resume .even-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills — 2 column grid */
    .resume .even-skills-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      column-gap: 16pt;
      row-gap: 4pt;
      font-size: 9.5pt;
    }

    .resume .even-skill-group {
      margin-bottom: 2pt;
    }

    .resume .even-skill-category {
      font-weight: 600;
      color: #607D8B !important;
    }

    .resume .even-skill-list {
      color: #444 !important;
    }

    /* Languages */
    .resume .even-languages {
      font-size: 9.5pt;
    }

    .resume .even-language + .even-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .even-lang-fluency {
      font-weight: 400;
      color: #666 !important;
    }
    """
  end
end
