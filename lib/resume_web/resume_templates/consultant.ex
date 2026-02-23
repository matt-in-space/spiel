defmodule ResumeWeb.ResumeTemplates.Consultant do
  @moduledoc """
  Consultant resume template.

  Corporate polished design with navy blue accents, bold header, small caps
  section titles, and compact inline skill lists. Projects an authoritative,
  senior-professional look.
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
    <header data-section="contact_info" class="cons-header">
      <h1 class="cons-name">{@contact.name}</h1>
      <div class="cons-contact-row">
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
    <section data-section="summary" class="cons-section">
      <h2 class="cons-section-title">Professional Summary</h2>
      <p class="cons-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">{exp.role}</span>
          <span class="cons-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="cons-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="cons-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">{edu.degree} in {edu.field}</span>
          <span class="cons-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="cons-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Skills</h2>
      <div class="cons-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="cons-skill-group"
        >
          <span class="cons-skill-category">{group.category}:</span>
          <span class="cons-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="cons-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="cons-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="cons-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="cons-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="cons-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="cons-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="cons-link">Link</a>
          </span>
          <span :if={pub.date} class="cons-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">{vol.role}</span>
          <span class="cons-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="cons-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="cons-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Languages</h2>
      <div class="cons-languages">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="cons-language"
        >
          {lang.name}<span :if={lang.fluency} class="cons-lang-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="cons-section">
      <h2 class="cons-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="cons-entry"
      >
        <div class="cons-entry-header">
          <span class="cons-entry-title">
            {award.title}
            <span :if={award.issuer} class="cons-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="cons-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="cons-body">{award.summary}</p>
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

    /* Header — bold with navy border */
    .resume .cons-header {
      text-align: left;
      margin-bottom: 12pt;
      padding-bottom: 8pt;
      border-bottom: 2.5pt solid #1B3A5C;
    }

    .resume .cons-name {
      font-size: 22pt;
      font-weight: 700;
      margin: 0 0 4pt 0;
      padding: 0;
      color: #1B3A5C !important;
    }

    .resume .cons-contact-row {
      font-size: 9pt;
      color: #555 !important;
    }

    .resume .cons-contact-row,
    .resume .cons-contact-row * {
      color: #555 !important;
    }

    .resume .cons-contact-row span {
      white-space: nowrap;
    }

    .resume .cons-contact-row span + span::before {
      content: " | ";
      color: #999 !important;
    }

    /* Sections */
    .resume .cons-section {
      margin-top: 11pt;
    }

    .resume .cons-section-title {
      font-size: 10pt;
      font-weight: 700;
      font-variant: small-caps;
      letter-spacing: 0.75pt;
      border-bottom: 1pt solid #1B3A5C;
      padding-bottom: 2pt;
      margin: 0 0 6pt 0;
      color: #1B3A5C !important;
      break-after: avoid;
    }

    .resume .cons-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .cons-entry {
      margin-bottom: 7pt;
    }

    .resume .cons-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .cons-entry-title {
      font-weight: 600;
      font-size: 10pt;
    }

    .resume .cons-entry-date {
      font-size: 8.5pt;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .cons-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
    }

    .resume .cons-entry-meta {
      font-weight: 400;
      color: #555 !important;
    }

    .resume .cons-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #1B3A5C !important;
    }

    /* Lists */
    .resume .cons-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .cons-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills — compact inline with bold categories */
    .resume .cons-skills {
      font-size: 9.5pt;
    }

    .resume .cons-skill-group {
      margin-bottom: 2pt;
      display: inline;
    }

    .resume .cons-skill-group + .cons-skill-group::before {
      content: "  |  ";
      color: #999 !important;
    }

    .resume .cons-skill-category {
      font-weight: 700;
      color: #1B3A5C !important;
    }

    .resume .cons-skill-list {
      color: #333 !important;
    }

    /* Languages */
    .resume .cons-languages {
      font-size: 9.5pt;
    }

    .resume .cons-language + .cons-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .cons-lang-fluency {
      font-weight: 400;
      color: #555 !important;
    }
    """
  end
end
