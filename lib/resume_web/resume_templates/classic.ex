defmodule ResumeWeb.ResumeTemplates.Classic do
  @moduledoc """
  Classic resume template.

  Traditional resume with Times New Roman serif fonts, centered header with
  horizontal rules (double-line top, single bottom), and a conservative
  black/dark gray color palette. Standard professional resume feel.
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
    <header data-section="contact_info" class="classic-header">
      <div class="classic-header-rule-top"></div>
      <h1 class="classic-name">{@contact.name}</h1>
      <div class="classic-contact-details">
        <span :if={@contact.email}>{@contact.email}</span>
        <span :if={@contact.phone}>{@contact.phone}</span>
        <span :if={@contact.location}>{@contact.location}</span>
        <span :for={w <- @contact.websites || []}>
          <a href={w.url}>{website_display(w)}</a>
        </span>
      </div>
      <div class="classic-header-rule-bottom"></div>
    </header>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section data-section="summary" class="classic-section">
      <h2 class="classic-section-title">PROFESSIONAL SUMMARY</h2>
      <p class="classic-body">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">WORK EXPERIENCE</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">{exp.role}</span>
          <span class="classic-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="classic-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="classic-list">
          <li :for={item <- exp.accomplishments}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">EDUCATION</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">{edu.degree} in {edu.field}</span>
          <span class="classic-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="classic-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">SKILLS</h2>
      <div class="classic-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="classic-skill-group"
        >
          <span class="classic-skill-category">{group.category}:</span>
          <span class="classic-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">CERTIFICATIONS</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="classic-entry-issuer">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="classic-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">PROJECTS</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="classic-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="classic-body">{proj.description}</p>
        <ul :if={proj.highlights != []} class="classic-list">
          <li :for={item <- proj.highlights}>{item}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">PUBLICATIONS</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="classic-entry-issuer">
              &nbsp;&mdash; {pub.publisher}
            </span>
            <a :if={pub.url} href={pub.url} class="classic-link">Link</a>
          </span>
          <span :if={pub.date} class="classic-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">VOLUNTEER WORK</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">{vol.role}</span>
          <span class="classic-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="classic-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="classic-body">{vol.description}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">LANGUAGES</h2>
      <div class="classic-skills">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="classic-language"
        >
          {lang.name}<span :if={lang.fluency} class="classic-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="classic-section">
      <h2 class="classic-section-title">AWARDS</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="classic-entry"
      >
        <div class="classic-entry-header">
          <span class="classic-entry-title">
            {award.title}
            <span :if={award.issuer} class="classic-entry-issuer">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="classic-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="classic-body">{award.summary}</p>
      </div>
    </section>
    """
  end

  @doc """
  Returns the CSS string for the Classic template.

  Traditional resume with Times New Roman, double-line top rule,
  and conservative black/dark gray palette.
  """
  def css do
    """
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    /* Root — traditional serif */
    .resume, .resume * {
      font-family: "Times New Roman", Times, serif !important;
      color: #000 !important;
    }

    .resume {
      font-size: 10.5pt;
      line-height: 1.4;
    }

    .resume a {
      color: #000 !important;
      text-decoration: underline;
    }

    /* Header */
    .resume .classic-header {
      text-align: center;
      margin-bottom: 10pt;
    }

    .resume .classic-header-rule-top {
      border-top: 2pt double #000;
      margin-bottom: 8pt;
    }

    .resume .classic-header-rule-bottom {
      border-bottom: 0.75pt solid #000;
      margin-top: 8pt;
    }

    .resume .classic-name {
      font-size: 22pt;
      font-weight: 700;
      margin: 0 0 4pt 0;
      padding: 0;
      letter-spacing: 1pt;
      text-transform: uppercase;
    }

    .resume .classic-contact-details,
    .resume .classic-contact-details * {
      font-size: 9.5pt;
      color: #333 !important;
    }

    .resume .classic-contact-details span {
      white-space: nowrap;
    }

    .resume .classic-contact-details span + span::before {
      content: " | ";
      color: #666 !important;
    }

    .resume .classic-contact-details a {
      color: #333 !important;
    }

    /* Sections */
    .resume .classic-section {
      margin-top: 10pt;
    }

    .resume .classic-section-title {
      font-size: 11pt;
      font-weight: 700;
      letter-spacing: 1pt;
      border-bottom: 0.75pt solid #000;
      padding-bottom: 2pt;
      margin: 0 0 6pt 0;
      color: #000 !important;
    }

    .resume .classic-body {
      margin: 2pt 0 0 0;
      font-size: 10pt;
      color: #222 !important;
    }

    /* Entries */
    .resume .classic-entry {
      margin-bottom: 6pt;
      break-inside: avoid;
    }

    .resume .classic-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }

    .resume .classic-entry-title {
      font-weight: 700;
      font-size: 10.5pt;
    }

    .resume .classic-entry-date {
      font-size: 9pt;
      color: #333 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .classic-entry-subtitle {
      font-size: 10pt;
      font-style: italic;
      color: #333 !important;
    }

    .resume .classic-entry-issuer {
      font-weight: 400;
      color: #333 !important;
    }

    .resume .classic-link {
      font-size: 9pt;
      margin-left: 4pt;
      color: #333 !important;
    }

    /* Lists */
    .resume .classic-list {
      margin: 2pt 0 0 0;
      padding-left: 16pt;
      font-size: 10pt;
      color: #222 !important;
      list-style-type: disc !important;
    }

    .resume .classic-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .classic-skills {
      font-size: 10pt;
    }

    .resume .classic-skill-group {
      margin-bottom: 2pt;
    }

    .resume .classic-skill-category {
      font-weight: 700;
    }

    .resume .classic-skill-list {
      color: #222 !important;
    }

    /* Languages */
    .resume .classic-language + .classic-language::before {
      content: " | ";
      color: #666 !important;
    }

    .resume .classic-language-fluency {
      font-weight: 400;
      font-style: italic;
      color: #333 !important;
    }
    """
  end
end
