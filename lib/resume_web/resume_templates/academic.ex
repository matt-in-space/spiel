defmodule ResumeWeb.ResumeTemplates.Academic do
  @moduledoc """
  Academic resume template.

  Formal academic CV style with serif typography, dense text,
  bold italic section titles, and traditional black/dark gray palette.
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
    <header class="acad-header" data-section="contact_info">
      <h1 class="acad-name">{@contact.name}</h1>
      <div class="acad-contact-row">
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
    <section class="acad-section" data-section="summary">
      <h2 class="acad-section-title">Summary</h2>
      <p class="acad-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Professional Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">{exp.role}</span>
          <span class="acad-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="acad-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="acad-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">{edu.degree} in {edu.field}</span>
          <span class="acad-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="acad-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Skills</h2>
      <div class="acad-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="acad-skill-group"
        >
          <span class="acad-skill-category">{group.category}:</span>
          <span class="acad-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="acad-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="acad-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="acad-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="acad-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="acad-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title acad-pub-title">
            {pub.title}
            <span :if={pub.publisher} class="acad-pub-publisher">{pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="acad-link">Link</a>
          </span>
          <span :if={pub.date} class="acad-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Service &amp; Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">{vol.role}</span>
          <span class="acad-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="acad-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="acad-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Languages</h2>
      <div class="acad-skills">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="acad-language"
        >
          {lang.name}<span :if={lang.fluency} class="acad-lang-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="acad-section">
      <h2 class="acad-section-title">Honors &amp; Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="acad-entry"
      >
        <div class="acad-entry-header">
          <span class="acad-entry-title">
            {award.title}
            <span :if={award.issuer} class="acad-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="acad-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="acad-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 0.6in 0.7in;
    }

    .resume, .resume * {
      font-family: Georgia, "Times New Roman", "Computer Modern", serif !important;
      color: #1a1a1a !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.35;
    }

    .resume a {
      color: #1a1a1a !important;
      text-decoration: underline;
    }

    /* Header — centered, traditional */
    .resume .acad-header {
      text-align: center;
      margin-bottom: 8pt;
      padding-bottom: 6pt;
      border-bottom: 0.75pt solid #1a1a1a;
    }

    .resume .acad-name {
      font-size: 18pt;
      font-weight: 700;
      margin: 0 0 4pt 0;
      padding: 0;
      letter-spacing: 1pt;
      color: #000 !important;
    }

    .resume .acad-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #333 !important;
      margin: 0 -5pt;
    }

    .resume .acad-contact-row,
    .resume .acad-contact-row * {
      color: #333 !important;
    }

    .resume .acad-contact-row span {
      white-space: nowrap;
      margin: 1.5pt 5pt;
    }

    .resume .acad-contact-row a {
      color: #333 !important;
    }

    /* Sections */
    .resume .acad-section {
      margin-top: 8pt;
    }

    .resume .acad-section-title {
      font-size: 11pt;
      font-weight: 700;
      font-style: italic;
      border-bottom: 0.5pt solid #666;
      padding-bottom: 1pt;
      margin: 0 0 5pt 0;
      color: #1a1a1a !important;
      break-after: avoid;
    }

    .resume .acad-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #222 !important;
    }

    /* Entries */
    .resume .acad-entry {
      margin-bottom: 5pt;
    }

    .resume .acad-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .acad-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .acad-entry-date {
      font-size: 9pt;
      color: #333 !important;
      white-space: nowrap;
      margin-left: 8pt;
      font-style: italic;
    }

    .resume .acad-entry-subtitle {
      font-size: 9.5pt;
      color: #444 !important;
    }

    .resume .acad-entry-meta {
      font-weight: 400;
      color: #444 !important;
    }

    .resume .acad-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #333 !important;
    }

    /* Publications — emphasis styling */
    .resume .acad-pub-title {
      font-style: italic;
    }

    .resume .acad-pub-publisher {
      font-style: normal;
      font-weight: 400;
      color: #333 !important;
    }

    .resume .acad-pub-publisher::before {
      content: ". ";
    }

    /* Lists */
    .resume .acad-list {
      margin: 2pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #222 !important;
      list-style-type: disc !important;
    }

    .resume .acad-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .acad-skills {
      font-size: 9.5pt;
    }

    .resume .acad-skill-group {
      margin-bottom: 2pt;
    }

    .resume .acad-skill-category {
      font-weight: 700;
    }

    .resume .acad-skill-list {
      color: #222 !important;
    }

    /* Languages */
    .resume .acad-language + .acad-language::before {
      content: " \\2022  ";
      color: #666 !important;
    }

    .resume .acad-lang-fluency {
      font-style: italic;
      font-weight: 400;
      color: #444 !important;
    }
    """
  end
end
