defmodule ResumeWeb.ResumeTemplates.Flat do
  @moduledoc """
  Flat resume template.

  Bold sans-serif typography with bright teal accent, colored background
  blocks for section headers, no borders, and clean separation via
  spacing and color. Modern flat design aesthetic.
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
    <header data-section="contact_info" class="flat-header">
      <h1 class="flat-name">{@contact.name}</h1>
      <div class="flat-contact-details">
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
    <section data-section="summary" class="flat-section">
      <h2 class="flat-section-title">Summary</h2>
      <p class="flat-body">{inline_format(@summary)}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">{exp.role}</span>
          <span class="flat-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="flat-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="flat-list">
          <li :for={item <- exp.accomplishments}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">{edu.degree} in {edu.field}</span>
          <span class="flat-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="flat-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Skills</h2>
      <div class="flat-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="flat-skill-group"
        >
          <span class="flat-skill-category">{group.category}:</span>
          <span class="flat-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="flat-entry-issuer">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="flat-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="flat-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="flat-body">{inline_format(proj.description)}</p>
        <ul :if={proj.highlights != []} class="flat-list">
          <li :for={item <- proj.highlights}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="flat-entry-issuer">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="flat-link">Link</a>
          </span>
          <span :if={pub.date} class="flat-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">{vol.role}</span>
          <span class="flat-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="flat-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="flat-body">{inline_format(vol.description)}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Languages</h2>
      <div class="flat-skills">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="flat-language"
        >
          {lang.name}<span :if={lang.fluency} class="flat-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="flat-section">
      <h2 class="flat-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="flat-entry"
      >
        <div class="flat-entry-header">
          <span class="flat-entry-title">
            {award.title}
            <span :if={award.issuer} class="flat-entry-issuer">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="flat-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="flat-body">{inline_format(award.summary)}</p>
      </div>
    </section>
    """
  end

  @doc """
  Returns the CSS string for the Flat template.

  Modern flat design with teal accent color blocks and bold sans-serif type.
  """
  def css do
    """
    #{inline_format_css()}
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    /* Root — bold sans-serif */
    .resume, .resume * {
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif !important;
      color: #212121 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.4;
    }

    .resume a {
      color: #00897B !important;
      text-decoration: none;
    }

    /* Header */
    .resume .flat-header {
      margin-bottom: 14pt;
      padding: 12pt 14pt;
      background-color: #00897B !important;
    }

    .resume .flat-header,
    .resume .flat-header * {
      color: #fff !important;
    }

    .resume .flat-name {
      font-size: 22pt;
      font-weight: 800;
      margin: 0 0 4pt 0;
      padding: 0;
      letter-spacing: 0.5pt;
      color: #fff !important;
    }

    .resume .flat-contact-details,
    .resume .flat-contact-details * {
      font-size: 9pt;
      color: rgba(255,255,255,0.9) !important;
    }

    .resume .flat-contact-details span {
      white-space: nowrap;
    }

    .resume .flat-contact-details span + span::before {
      content: " \\2022  ";
      color: rgba(255,255,255,0.6) !important;
    }

    .resume .flat-contact-details a {
      color: rgba(255,255,255,0.9) !important;
    }

    /* Sections */
    .resume .flat-section {
      margin-top: 12pt;
    }

    .resume .flat-section-title {
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1pt;
      color: #fff !important;
      background-color: #00897B !important;
      padding: 3pt 8pt;
      margin: 0 0 8pt 0;
      break-after: avoid;
    }

    .resume .flat-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #424242 !important;
    }

    /* Entries */
    .resume .flat-entry {
      margin-bottom: 8pt;
    }

    .resume .flat-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .flat-entry-title {
      font-weight: 700;
      font-size: 10pt;
      color: #212121 !important;
    }

    .resume .flat-entry-date {
      font-size: 8.5pt;
      color: #757575 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .flat-entry-subtitle {
      font-size: 9.5pt;
      color: #00897B !important;
      font-weight: 500;
    }

    .resume .flat-entry-issuer {
      font-weight: 400;
      color: #616161 !important;
    }

    .resume .flat-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #00897B !important;
    }

    /* Lists */
    .resume .flat-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #424242 !important;
      list-style-type: disc !important;
    }

    .resume .flat-list li {
      margin-bottom: 2pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .flat-skills {
      font-size: 9.5pt;
    }

    .resume .flat-skill-group {
      margin-bottom: 3pt;
    }

    .resume .flat-skill-category {
      font-weight: 700;
      color: #00897B !important;
    }

    .resume .flat-skill-list {
      color: #424242 !important;
    }

    /* Languages */
    .resume .flat-language + .flat-language::before {
      content: " \\2022  ";
      color: #bbb !important;
    }

    .resume .flat-language-fluency {
      font-weight: 400;
      color: #757575 !important;
    }
    """
  end
end
