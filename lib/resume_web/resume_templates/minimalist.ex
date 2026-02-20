defmodule ResumeWeb.ResumeTemplates.Minimalist do
  @moduledoc """
  Minimalist resume template.

  Ultra-sparse design with maximum whitespace, thin hairline borders,
  light gray uppercase section titles, and understated typography.
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
    <header class="mini-header" data-section="contact_info">
      <h1 class="mini-name">{@contact.name}</h1>
      <div class="mini-contact-row">
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
    <section class="mini-section" data-section="summary">
      <h2 class="mini-section-title">Summary</h2>
      <p class="mini-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">{exp.role}</span>
          <span class="mini-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="mini-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="mini-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">{edu.degree} in {edu.field}</span>
          <span class="mini-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="mini-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Skills</h2>
      <div class="mini-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="mini-skill-group"
        >
          <span class="mini-skill-category">{group.category}:</span>
          <span class="mini-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="mini-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="mini-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="mini-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="mini-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="mini-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="mini-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="mini-link">Link</a>
          </span>
          <span :if={pub.date} class="mini-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Volunteer</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">{vol.role}</span>
          <span class="mini-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="mini-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="mini-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Languages</h2>
      <div class="mini-skills">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="mini-language"
        >
          {lang.name}<span :if={lang.fluency} class="mini-lang-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="mini-section">
      <h2 class="mini-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="mini-entry"
      >
        <div class="mini-entry-header">
          <span class="mini-entry-title">
            {award.title}
            <span :if={award.issuer} class="mini-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="mini-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="mini-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 1in 1in;
    }

    .resume, .resume * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #333 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.5;
    }

    .resume a {
      color: #333 !important;
      text-decoration: none;
    }

    /* Header — large name, understated contact */
    .resume .mini-header {
      margin-bottom: 20pt;
      padding-bottom: 12pt;
      border-bottom: 0.5pt solid #ddd;
    }

    .resume .mini-name {
      font-size: 28pt;
      font-weight: 300;
      margin: 0 0 8pt 0;
      padding: 0;
      letter-spacing: 1pt;
      color: #222 !important;
    }

    .resume .mini-contact-row {
      display: flex;
      flex-wrap: wrap;
      gap: 4pt 16pt;
      font-size: 8.5pt;
      color: #999 !important;
    }

    .resume .mini-contact-row,
    .resume .mini-contact-row * {
      color: #999 !important;
    }

    .resume .mini-contact-row span {
      white-space: nowrap;
    }

    .resume .mini-contact-row a {
      color: #999 !important;
    }

    /* Sections — maximum whitespace */
    .resume .mini-section {
      margin-top: 16pt;
    }

    .resume .mini-section-title {
      font-size: 8pt;
      font-weight: 400;
      text-transform: uppercase;
      letter-spacing: 3pt;
      margin: 0 0 8pt 0;
      padding-bottom: 4pt;
      border-bottom: 0.5pt solid #ddd;
      color: #999 !important;
    }

    .resume .mini-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #444 !important;
    }

    /* Entries */
    .resume .mini-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .mini-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .mini-entry-title {
      font-weight: 500;
      font-size: 10pt;
      color: #222 !important;
    }

    .resume .mini-entry-date {
      font-size: 8.5pt;
      color: #999 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .mini-entry-subtitle {
      font-size: 9.5pt;
      color: #888 !important;
    }

    .resume .mini-entry-meta {
      font-weight: 400;
      color: #888 !important;
    }

    .resume .mini-link {
      font-size: 8pt;
      margin-left: 4pt;
      color: #999 !important;
    }

    /* Lists */
    .resume .mini-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #444 !important;
      list-style-type: disc !important;
    }

    .resume .mini-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .mini-skills {
      font-size: 9.5pt;
    }

    .resume .mini-skill-group {
      margin-bottom: 2pt;
    }

    .resume .mini-skill-category {
      font-weight: 500;
      color: #555 !important;
    }

    .resume .mini-skill-list {
      color: #666 !important;
    }

    /* Languages */
    .resume .mini-language + .mini-language::before {
      content: " \\2022  ";
      color: #ccc !important;
    }

    .resume .mini-lang-fluency {
      font-weight: 400;
      color: #999 !important;
    }
    """
  end
end
