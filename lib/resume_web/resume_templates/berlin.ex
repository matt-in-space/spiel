defmodule ResumeWeb.ResumeTemplates.Berlin do
  @moduledoc """
  Berlin resume template.

  European grid-based design with strong structural lines, bold geometric feel,
  thick black top borders on sections, uppercase name with wide letter-spacing,
  and two-tier header with pipe-separated contact details.
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
    <header data-section="contact_info" class="bln-header">
      <h1 class="bln-name">{@contact.name}</h1>
      <div class="bln-contact-row">
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
    <section data-section="summary" class="bln-section">
      <h2 class="bln-section-title">Profile</h2>
      <p class="bln-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">{exp.role}</span>
          <span class="bln-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="bln-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="bln-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">{edu.degree} in {edu.field}</span>
          <span class="bln-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="bln-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Skills</h2>
      <div class="bln-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="bln-skill-group"
        >
          <span class="bln-skill-category">{group.category}:</span>
          <span class="bln-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="bln-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="bln-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="bln-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="bln-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="bln-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="bln-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="bln-link">Link</a>
          </span>
          <span :if={pub.date} class="bln-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">{vol.role}</span>
          <span class="bln-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="bln-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="bln-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Languages</h2>
      <div class="bln-languages">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="bln-language"
        >
          {lang.name}<span :if={lang.fluency} class="bln-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="bln-section">
      <h2 class="bln-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="bln-entry"
      >
        <div class="bln-entry-header">
          <span class="bln-entry-title">
            {award.title}
            <span :if={award.issuer} class="bln-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="bln-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="bln-body">{award.summary}</p>
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

    /* Root — system sans-serif, charcoal/black only */
    .resume, .resume * {
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif !important;
      color: #1a1a1a !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.4;
    }

    .resume a {
      color: #1a1a1a !important;
      text-decoration: none;
    }

    /* Header — two-tier: name on top, contact below with pipe separators */
    .resume .bln-header {
      margin-bottom: 14pt;
      padding-bottom: 10pt;
      border-bottom: 3pt solid #000;
    }

    .resume .bln-name {
      font-size: 22pt;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 4pt;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #000 !important;
    }

    .resume .bln-contact-row {
      display: flex;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #333 !important;
    }

    .resume .bln-contact-row span {
      white-space: nowrap;
    }

    .resume .bln-contact-row span + span::before {
      content: "  |  ";
      color: #999 !important;
    }

    .resume .bln-contact-row,
    .resume .bln-contact-row * {
      color: #333 !important;
    }

    /* Sections — thick black top border */
    .resume .bln-section {
      margin-top: 14pt;
    }

    .resume .bln-section-title {
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 2pt;
      border-top: 3pt solid #000;
      padding-top: 4pt;
      margin: 0 0 8pt 0;
      color: #000 !important;
    }

    .resume .bln-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .bln-entry {
      margin-bottom: 8pt;
      break-inside: avoid;
    }

    .resume .bln-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .bln-entry-title {
      font-weight: 600;
      font-size: 10pt;
      color: #000 !important;
    }

    .resume .bln-entry-date {
      font-size: 8.5pt;
      color: #555 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .bln-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
    }

    .resume .bln-entry-meta {
      font-weight: 400;
      color: #555 !important;
    }

    .resume .bln-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #555 !important;
    }

    /* Lists — override Tailwind Preflight reset */
    .resume .bln-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .bln-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .bln-skills {
      font-size: 9.5pt;
    }

    .resume .bln-skill-group {
      margin-bottom: 2pt;
    }

    .resume .bln-skill-category {
      font-weight: 700;
      color: #000 !important;
    }

    .resume .bln-skill-list {
      color: #333 !important;
    }

    /* Languages */
    .resume .bln-languages {
      font-size: 9.5pt;
    }

    .resume .bln-language + .bln-language::before {
      content: "  |  ";
      color: #999 !important;
    }

    .resume .bln-language-fluency {
      font-weight: 400;
      color: #555 !important;
    }
    """
  end
end
