defmodule ResumeWeb.ResumeTemplates.Stackoverflow do
  @moduledoc """
  StackOverflow resume template.

  Developer community inspired design with orange accents, tag-style skills,
  and orange left-border section dividers.
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
    <header data-section="contact_info" class="stack-header">
      <h1 class="stack-name">{@contact.name}</h1>
      <div class="stack-contact-row">
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
    <section data-section="summary" class="stack-section">
      <h2 class="stack-section-title">Summary</h2>
      <p class="stack-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">{exp.role}</span>
          <span class="stack-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="stack-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="stack-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">{edu.degree} in {edu.field}</span>
          <span class="stack-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="stack-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Skills</h2>
      <div class="stack-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="stack-skill-group"
        >
          <span class="stack-skill-category">{group.category}</span>
          <div class="stack-skill-tags">
            <span :for={skill <- group.skills} class="stack-skill-tag">{skill}</span>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="stack-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="stack-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="stack-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="stack-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="stack-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="stack-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="stack-link">Link</a>
          </span>
          <span :if={pub.date} class="stack-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">{vol.role}</span>
          <span class="stack-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="stack-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="stack-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Languages</h2>
      <div class="stack-skill-tags">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="stack-skill-tag"
        >
          {lang.name}<span :if={lang.fluency} class="stack-entry-meta"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="stack-section">
      <h2 class="stack-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="stack-entry"
      >
        <div class="stack-entry-header">
          <span class="stack-entry-title">
            {award.title}
            <span :if={award.issuer} class="stack-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="stack-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="stack-body">{award.summary}</p>
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
      color: #242729 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
    }

    .resume a {
      color: #0077cc !important;
      text-decoration: none;
    }

    /* Header — left-aligned, contact in a row */
    .resume .stack-header {
      margin-bottom: 12pt;
      padding-bottom: 10pt;
      border-bottom: 3pt solid #F48024;
    }

    .resume .stack-name {
      font-size: 22pt;
      font-weight: 700;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #242729 !important;
    }

    .resume .stack-contact-row {
      display: flex;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #6a737c !important;
      margin: 0 -7pt;
    }

    .resume .stack-contact-row,
    .resume .stack-contact-row * {
      color: #6a737c !important;
    }

    .resume .stack-contact-row span {
      white-space: nowrap;
      margin: 2pt 7pt;
    }

    .resume .stack-contact-row a {
      color: #0077cc !important;
    }

    /* Sections — orange left border instead of bottom border */
    .resume .stack-section {
      margin-top: 12pt;
    }

    .resume .stack-section-title {
      font-size: 11pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5pt;
      border-left: 3pt solid #F48024;
      padding-left: 8pt;
      margin: 0 0 8pt 0;
      color: #242729 !important;
      break-after: avoid;
    }

    .resume .stack-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #3b4045 !important;
    }

    /* Entries */
    .resume .stack-entry {
      margin-bottom: 8pt;
    }

    .resume .stack-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .stack-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .stack-entry-date {
      font-size: 8.5pt;
      color: #6a737c !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .stack-entry-subtitle {
      font-size: 9.5pt;
      color: #6a737c !important;
    }

    .resume .stack-entry-meta {
      font-weight: 400;
      color: #6a737c !important;
    }

    .resume .stack-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #0077cc !important;
    }

    /* Lists */
    .resume .stack-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #3b4045 !important;
      list-style-type: disc !important;
    }

    .resume .stack-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills — tag style with light orange background */
    .resume .stack-skills {
      font-size: 9.5pt;
    }

    .resume .stack-skill-group {
      margin-bottom: 6pt;
    }

    .resume .stack-skill-category {
      font-weight: 700;
      font-size: 9pt;
      color: #242729 !important;
      display: block;
      margin-bottom: 3pt;
    }

    .resume .stack-skill-tags {
      display: flex;
      flex-wrap: wrap;
      margin: -2pt;
    }

    .resume .stack-skill-tags .stack-skill-tag {
      margin: 2pt;
    }

    .resume .stack-skill-tag {
      display: inline-block;
      background-color: #FFF4E6 !important;
      border: 1pt solid #F48024;
      border-radius: 3pt;
      padding: 1pt 7pt;
      font-size: 8.5pt;
      color: #9a6318 !important;
      white-space: nowrap;
    }
    """
  end
end
