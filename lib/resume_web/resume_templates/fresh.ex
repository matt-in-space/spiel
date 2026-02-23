defmodule ResumeWeb.ResumeTemplates.Fresh do
  @moduledoc """
  Fresh resume template.

  Modern, clean, vibrant design with teal accents and pill-style skill tags.
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
    <header data-section="contact_info" class="fresh-header">
      <h1 class="fresh-name">{@contact.name}</h1>
      <div class="fresh-contact-row">
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
    <section data-section="summary" class="fresh-section">
      <h2 class="fresh-section-title">Summary</h2>
      <p class="fresh-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">{exp.role}</span>
          <span class="fresh-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="fresh-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="fresh-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">{edu.degree} in {edu.field}</span>
          <span class="fresh-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="fresh-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Skills</h2>
      <div class="fresh-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="fresh-skill-group"
        >
          <span class="fresh-skill-category">{group.category}</span>
          <div class="fresh-skill-tags">
            <span :for={skill <- group.skills} class="fresh-skill-tag">{skill}</span>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="fresh-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="fresh-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="fresh-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="fresh-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="fresh-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="fresh-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="fresh-link">Link</a>
          </span>
          <span :if={pub.date} class="fresh-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">{vol.role}</span>
          <span class="fresh-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="fresh-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="fresh-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Languages</h2>
      <div class="fresh-skill-tags">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="fresh-skill-tag"
        >
          {lang.name}<span :if={lang.fluency} class="fresh-entry-meta">&nbsp;&mdash; {lang.fluency}</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="fresh-section">
      <h2 class="fresh-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="fresh-entry"
      >
        <div class="fresh-entry-header">
          <span class="fresh-entry-title">
            {award.title}
            <span :if={award.issuer} class="fresh-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="fresh-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="fresh-body">{award.summary}</p>
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
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif !important;
      color: #1e293b !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
    }

    .resume a {
      color: #0d9488 !important;
      text-decoration: none;
    }

    /* Header */
    .resume .fresh-header {
      text-align: center;
      margin-bottom: 14pt;
      padding-bottom: 10pt;
      border-bottom: 2.5pt solid #0d9488;
    }

    .resume .fresh-name {
      font-size: 24pt;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 2pt;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #0f172a !important;
    }

    .resume .fresh-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #64748b !important;
      margin: 0 -7pt;
    }

    .resume .fresh-contact-row span {
      white-space: nowrap;
      margin: 2pt 7pt;
    }

    .resume .fresh-contact-row a {
      color: #0d9488 !important;
    }

    /* Sections */
    .resume .fresh-section {
      margin-top: 12pt;
    }

    .resume .fresh-section-title {
      font-size: 9pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1.5pt;
      border-bottom: 1.5pt solid #0d9488;
      padding-bottom: 3pt;
      margin: 0 0 8pt 0;
      color: #0d9488 !important;
      break-after: avoid;
    }

    .resume .fresh-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #334155 !important;
    }

    /* Entries */
    .resume .fresh-entry {
      margin-bottom: 8pt;
    }

    .resume .fresh-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .fresh-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .fresh-entry-date {
      font-size: 8.5pt;
      color: #64748b !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .fresh-entry-subtitle {
      font-size: 9.5pt;
      color: #64748b !important;
    }

    .resume .fresh-entry-meta {
      font-weight: 400;
      color: #64748b !important;
    }

    .resume .fresh-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #0d9488 !important;
    }

    /* Lists */
    .resume .fresh-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #334155 !important;
      list-style-type: disc !important;
    }

    .resume .fresh-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills — pill tags */
    .resume .fresh-skills {
      font-size: 9.5pt;
    }

    .resume .fresh-skill-group {
      margin-bottom: 6pt;
    }

    .resume .fresh-skill-category {
      font-weight: 700;
      font-size: 9pt;
      color: #0d9488 !important;
      display: block;
      margin-bottom: 3pt;
    }

    .resume .fresh-skill-tags {
      display: flex;
      flex-wrap: wrap;
      margin: -2pt;
    }

    .resume .fresh-skill-tags .fresh-skill-tag {
      margin: 2pt;
    }

    .resume .fresh-skill-tag {
      display: inline-block;
      border: 1pt solid #0d9488;
      border-radius: 10pt;
      padding: 1pt 8pt;
      font-size: 8.5pt;
      color: #0d9488 !important;
      white-space: nowrap;
    }
    """
  end
end
