defmodule ResumeWeb.ResumeTemplates.Nordic do
  @moduledoc """
  Nordic resume template.

  Scandinavian minimal design with muted blue-gray accents, generous whitespace,
  thin borders, and understated typography. Calm, professional, understated.
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
    <header data-section="contact_info" class="nord-header">
      <h1 class="nord-name">{@contact.name}</h1>
      <div class="nord-contact-row">
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
    <section data-section="summary" class="nord-section">
      <h2 class="nord-section-title">Summary</h2>
      <p class="nord-body">{inline_format(@summary)}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">{exp.role}</span>
          <span class="nord-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="nord-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="nord-list">
          <li :for={item <- exp.accomplishments}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">{edu.degree} in {edu.field}</span>
          <span class="nord-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="nord-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Skills</h2>
      <div class="nord-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="nord-skill-group"
        >
          <span class="nord-skill-category">{group.category}:</span>
          <span class="nord-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="nord-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="nord-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="nord-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="nord-body">{inline_format(proj.description)}</p>
        <ul :if={proj.highlights != []} class="nord-list">
          <li :for={item <- proj.highlights}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="nord-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="nord-link">Link</a>
          </span>
          <span :if={pub.date} class="nord-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">{vol.role}</span>
          <span class="nord-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="nord-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="nord-body">{inline_format(vol.description)}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Languages</h2>
      <div class="nord-languages">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="nord-language"
        >
          {lang.name}<span :if={lang.fluency} class="nord-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="nord-section">
      <h2 class="nord-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="nord-entry"
      >
        <div class="nord-entry-header">
          <span class="nord-entry-title">
            {award.title}
            <span :if={award.issuer} class="nord-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="nord-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="nord-body">{inline_format(award.summary)}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    #{inline_format_css()}
    @page {
      size: letter;
      margin: 0.85in 0.95in;
    }

    /* Root — system sans-serif, light weight, muted blue-gray accent */
    .resume, .resume * {
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif !important;
      color: #37474F !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.5;
    }

    .resume a {
      color: #546E7A !important;
      text-decoration: none;
    }

    /* Header */
    .resume .nord-header {
      margin-bottom: 18pt;
      padding-bottom: 12pt;
      border-bottom: 0.5pt solid #B0BEC5;
    }

    .resume .nord-name {
      font-size: 22pt;
      font-weight: 300;
      margin: 0 0 8pt 0;
      padding: 0;
      color: #263238 !important;
      letter-spacing: 1pt;
    }

    .resume .nord-contact-row {
      display: flex;
      flex-wrap: wrap;
      font-size: 9pt;
      font-weight: 300;
      color: #78909C !important;
      margin: 0 -8pt;
    }

    .resume .nord-contact-row span {
      white-space: nowrap;
      margin: 2pt 8pt;
    }

    .resume .nord-contact-row,
    .resume .nord-contact-row * {
      color: #78909C !important;
    }

    .resume .nord-contact-row a {
      color: #546E7A !important;
    }

    /* Sections */
    .resume .nord-section {
      margin-top: 16pt;
    }

    .resume .nord-section-title {
      font-size: 9pt;
      font-weight: 400;
      text-transform: uppercase;
      letter-spacing: 2pt;
      border-bottom: 0.5pt solid #CFD8DC;
      padding-bottom: 4pt;
      margin: 0 0 10pt 0;
      color: #546E7A !important;
      break-after: avoid;
    }

    .resume .nord-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      font-weight: 300;
      color: #455A64 !important;
    }

    /* Entries */
    .resume .nord-entry {
      margin-bottom: 10pt;
    }

    .resume .nord-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .nord-entry-title {
      font-weight: 500;
      font-size: 10pt;
      color: #263238 !important;
    }

    .resume .nord-entry-date {
      font-size: 8.5pt;
      font-weight: 300;
      color: #78909C !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .nord-entry-subtitle {
      font-size: 9.5pt;
      font-weight: 300;
      color: #607D8B !important;
    }

    .resume .nord-entry-meta {
      font-weight: 300;
      color: #78909C !important;
    }

    .resume .nord-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #546E7A !important;
    }

    /* Lists — override Tailwind Preflight reset */
    .resume .nord-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      font-weight: 300;
      color: #455A64 !important;
      list-style-type: disc !important;
    }

    .resume .nord-list li {
      margin-bottom: 2pt;
      display: list-item !important;
    }

    /* Skills — simple comma-separated text */
    .resume .nord-skills {
      font-size: 9.5pt;
      font-weight: 300;
    }

    .resume .nord-skill-group {
      margin-bottom: 3pt;
    }

    .resume .nord-skill-category {
      font-weight: 500;
      color: #546E7A !important;
    }

    .resume .nord-skill-list {
      color: #455A64 !important;
    }

    /* Languages */
    .resume .nord-languages {
      font-size: 9.5pt;
      font-weight: 300;
    }

    .resume .nord-language + .nord-language::before {
      content: ", ";
      color: #90A4AE !important;
    }

    .resume .nord-language-fluency {
      font-weight: 300;
      color: #78909C !important;
    }
    """
  end
end
