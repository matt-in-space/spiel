defmodule ResumeWeb.ResumeTemplates.Macchiato do
  @moduledoc """
  Macchiato resume template.

  Warm brown and cream palette with rounded section separators,
  pill-style skill tags, and a friendly, approachable feel.
  Serif headings with sans-serif body text.
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
    <header class="macc-header" data-section="contact_info">
      <h1 class="macc-name">{@contact.name}</h1>
      <div class="macc-contact-row">
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
    <section class="macc-section" data-section="summary">
      <h2 class="macc-section-title">Summary</h2>
      <p class="macc-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">{exp.role}</span>
          <span class="macc-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="macc-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="macc-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">{edu.degree} in {edu.field}</span>
          <span class="macc-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="macc-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Skills</h2>
      <div class="macc-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="macc-skill-group"
        >
          <span class="macc-skill-category">{group.category}</span>
          <div class="macc-skill-tags">
            <span :for={skill <- group.skills} class="macc-skill-tag">{skill}</span>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="macc-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="macc-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="macc-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="macc-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="macc-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="macc-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="macc-link">Link</a>
          </span>
          <span :if={pub.date} class="macc-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">{vol.role}</span>
          <span class="macc-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="macc-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="macc-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Languages</h2>
      <div class="macc-skill-tags">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="macc-skill-tag"
        >
          {lang.name}<span :if={lang.fluency} class="macc-entry-meta"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="macc-section">
      <h2 class="macc-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="macc-entry"
      >
        <div class="macc-entry-header">
          <span class="macc-entry-title">
            {award.title}
            <span :if={award.issuer} class="macc-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="macc-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="macc-body">{award.summary}</p>
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
      color: #3E2723 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
    }

    .resume a {
      color: #6D4C41 !important;
      text-decoration: none;
    }

    /* Header — warm, centered, rounded bottom border */
    .resume .macc-header {
      text-align: center;
      margin-bottom: 14pt;
      padding-bottom: 12pt;
      border-bottom: 2pt solid #D7CCC8;
      border-radius: 0 0 8pt 8pt;
    }

    .resume .macc-name {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 24pt;
      font-weight: 700;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #4E342E !important;
    }

    .resume .macc-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      gap: 4pt 14pt;
      font-size: 9pt;
      color: #795548 !important;
    }

    .resume .macc-contact-row,
    .resume .macc-contact-row * {
      color: #795548 !important;
    }

    .resume .macc-contact-row span {
      white-space: nowrap;
    }

    .resume .macc-contact-row a {
      color: #6D4C41 !important;
    }

    /* Sections — rounded dividers */
    .resume .macc-section {
      margin-top: 12pt;
    }

    .resume .macc-section-title {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 11pt;
      font-weight: 700;
      padding-bottom: 3pt;
      margin: 0 0 8pt 0;
      border-bottom: 1.5pt solid #D7CCC8;
      border-radius: 0 0 4pt 4pt;
      color: #5D4037 !important;
    }

    .resume .macc-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #4E342E !important;
    }

    /* Entries */
    .resume .macc-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .macc-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .macc-entry-title {
      font-weight: 600;
      font-size: 10pt;
      color: #3E2723 !important;
    }

    .resume .macc-entry-date {
      font-size: 8.5pt;
      color: #8D6E63 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .macc-entry-subtitle {
      font-size: 9.5pt;
      color: #795548 !important;
    }

    .resume .macc-entry-meta {
      font-weight: 400;
      color: #795548 !important;
    }

    .resume .macc-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #6D4C41 !important;
    }

    /* Lists */
    .resume .macc-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #4E342E !important;
      list-style-type: disc !important;
    }

    .resume .macc-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills — warm-toned pill tags */
    .resume .macc-skills {
      font-size: 9.5pt;
    }

    .resume .macc-skill-group {
      margin-bottom: 6pt;
    }

    .resume .macc-skill-category {
      font-family: Georgia, "Times New Roman", serif !important;
      font-weight: 700;
      font-size: 9pt;
      color: #5D4037 !important;
      display: block;
      margin-bottom: 3pt;
    }

    .resume .macc-skill-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 4pt;
    }

    .resume .macc-skill-tag {
      display: inline-block;
      background-color: #EFEBE9 !important;
      border: 1pt solid #A1887F;
      border-radius: 10pt;
      padding: 1pt 8pt;
      font-size: 8.5pt;
      color: #5D4037 !important;
      white-space: nowrap;
    }
    """
  end
end
