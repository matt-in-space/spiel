defmodule ResumeWeb.ResumeTemplates.Editorial do
  @moduledoc """
  Editorial resume template.

  Magazine/editorial inspired design with strong typography hierarchy,
  serif name, small-caps section titles with top borders, and dark red accents.
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
    <header data-section="contact_info" class="edit-header">
      <h1 class="edit-name">{@contact.name}</h1>
      <div class="edit-contact-row">
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
    <section data-section="summary" class="edit-section">
      <h2 class="edit-section-title">Summary</h2>
      <p class="edit-body">{inline_format(@summary)}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Experience</h2>
      <div
        :for={{exp, idx} <- Enum.with_index(@experiences)}
        data-section="work_experience"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">{exp.role}</span>
          <span class="edit-entry-date">
            {format_date_range(exp.start_date, exp.end_date, exp.current)}
          </span>
        </div>
        <div class="edit-entry-subtitle">{exp.company}</div>
        <ul :if={exp.accomplishments != []} class="edit-list">
          <li :for={item <- exp.accomplishments}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Education</h2>
      <div
        :for={{edu, idx} <- Enum.with_index(@entries)}
        data-section="education"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">{edu.degree} in {edu.field}</span>
          <span class="edit-entry-date">
            {format_date_range(edu.start_date, edu.end_date, false)}
          </span>
        </div>
        <div class="edit-entry-subtitle">{edu.institution}</div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Skills</h2>
      <div class="edit-skills">
        <div
          :for={{group, idx} <- Enum.with_index(@groups)}
          data-section="skills"
          data-section-index={idx}
          class="edit-skill-group"
        >
          <span class="edit-skill-category">{group.category}:</span>
          <span class="edit-skill-list">{Enum.join(group.skills, ", ")}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Certifications</h2>
      <div
        :for={{cert, idx} <- Enum.with_index(@certs)}
        data-section="certifications"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">
            {cert.name}
            <span :if={cert.issuer} class="edit-entry-meta">&nbsp;&mdash; {cert.issuer}</span>
          </span>
          <span :if={cert.date} class="edit-entry-date">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Projects</h2>
      <div
        :for={{proj, idx} <- Enum.with_index(@projects)}
        data-section="projects"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">
            {proj.name}
            <a :if={proj.url} href={proj.url} class="edit-link">{proj.url}</a>
          </span>
        </div>
        <p :if={proj.description} class="edit-body">{inline_format(proj.description)}</p>
        <ul :if={proj.highlights != []} class="edit-list">
          <li :for={item <- proj.highlights}>{inline_format(item)}</li>
        </ul>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Publications</h2>
      <div
        :for={{pub, idx} <- Enum.with_index(@pubs)}
        data-section="publications"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">
            {pub.title}
            <span :if={pub.publisher} class="edit-entry-meta">&nbsp;&mdash; {pub.publisher}</span>
            <a :if={pub.url} href={pub.url} class="edit-link">Link</a>
          </span>
          <span :if={pub.date} class="edit-entry-date">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Volunteer Work</h2>
      <div
        :for={{vol, idx} <- Enum.with_index(@entries)}
        data-section="volunteer_work"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">{vol.role}</span>
          <span class="edit-entry-date">
            {format_date_range(vol.start_date, vol.end_date, false)}
          </span>
        </div>
        <div class="edit-entry-subtitle">{vol.organization}</div>
        <p :if={vol.description} class="edit-body">{inline_format(vol.description)}</p>
      </div>
    </section>
    """
  end

  defp languages_section(%{languages: []} = assigns), do: ~H""

  defp languages_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Languages</h2>
      <div class="edit-languages">
        <span
          :for={{lang, idx} <- Enum.with_index(@languages)}
          data-section="languages"
          data-section-index={idx}
          class="edit-language"
        >
          {lang.name}<span :if={lang.fluency} class="edit-language-fluency"> ({lang.fluency})</span>
        </span>
      </div>
    </section>
    """
  end

  defp awards_section(%{awards: []} = assigns), do: ~H""

  defp awards_section(assigns) do
    ~H"""
    <section class="edit-section">
      <h2 class="edit-section-title">Awards</h2>
      <div
        :for={{award, idx} <- Enum.with_index(@awards)}
        data-section="awards"
        data-section-index={idx}
        class="edit-entry"
      >
        <div class="edit-entry-header">
          <span class="edit-entry-title">
            {award.title}
            <span :if={award.issuer} class="edit-entry-meta">&nbsp;&mdash; {award.issuer}</span>
          </span>
          <span :if={award.date} class="edit-entry-date">{format_flex_date(award.date)}</span>
        </div>
        <p :if={award.summary} class="edit-body">{inline_format(award.summary)}</p>
      </div>
    </section>
    """
  end

  def css do
    """
    #{inline_format_css()}
    @page {
      size: letter;
      margin: 0.75in 0.85in;
    }

    /* Root — serif name, sans-serif body, dark red accent */
    .resume, .resume * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #222 !important;
    }

    .resume {
      font-size: 10pt;
      line-height: 1.45;
    }

    .resume a {
      color: #8B0000 !important;
      text-decoration: none;
    }

    /* Header */
    .resume .edit-header {
      text-align: center;
      margin-bottom: 14pt;
      padding-bottom: 10pt;
      border-bottom: 0.5pt solid #ccc;
    }

    .resume .edit-name {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 28pt;
      font-weight: 700;
      margin: 0 0 6pt 0;
      padding: 0;
      color: #111 !important;
      letter-spacing: 0.5pt;
    }

    .resume .edit-contact-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      font-size: 9pt;
      color: #555 !important;
      margin: 0 -7pt;
    }

    .resume .edit-contact-row span {
      white-space: nowrap;
      margin: 2pt 7pt;
    }

    .resume .edit-contact-row a {
      color: #8B0000 !important;
    }

    /* Sections */
    .resume .edit-section {
      margin-top: 14pt;
    }

    .resume .edit-section-title {
      font-family: Georgia, "Times New Roman", serif !important;
      font-size: 10pt;
      font-weight: 700;
      font-variant: small-caps;
      letter-spacing: 1pt;
      text-transform: lowercase;
      border-top: 0.75pt solid #8B0000;
      padding-top: 4pt;
      margin: 0 0 8pt 0;
      color: #8B0000 !important;
      break-after: avoid;
    }

    .resume .edit-body {
      margin: 2pt 0 0 0;
      font-size: 9.5pt;
      color: #333 !important;
    }

    /* Entries */
    .resume .edit-entry {
      margin-bottom: 8pt;
    }

    .resume .edit-entry-header {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      break-inside: avoid;
    }

    .resume .edit-entry-title {
      font-weight: 600;
      font-size: 10pt;
      color: #111 !important;
    }

    .resume .edit-entry-date {
      font-size: 8.5pt;
      font-style: italic;
      color: #666 !important;
      white-space: nowrap;
      margin-left: 8pt;
    }

    .resume .edit-entry-subtitle {
      font-size: 9.5pt;
      color: #555 !important;
      font-style: italic;
    }

    .resume .edit-entry-meta {
      font-weight: 400;
      color: #666 !important;
    }

    .resume .edit-link {
      font-size: 8.5pt;
      margin-left: 4pt;
      color: #8B0000 !important;
    }

    /* Lists — override Tailwind Preflight reset */
    .resume .edit-list {
      margin: 3pt 0 0 0;
      padding-left: 14pt;
      font-size: 9.5pt;
      color: #333 !important;
      list-style-type: disc !important;
    }

    .resume .edit-list li {
      margin-bottom: 1pt;
      display: list-item !important;
    }

    /* Skills */
    .resume .edit-skills {
      font-size: 9.5pt;
    }

    .resume .edit-skill-group {
      margin-bottom: 2pt;
    }

    .resume .edit-skill-category {
      font-weight: 600;
      color: #8B0000 !important;
    }

    .resume .edit-skill-list {
      color: #333 !important;
    }

    /* Languages */
    .resume .edit-languages {
      font-size: 9.5pt;
    }

    .resume .edit-language + .edit-language::before {
      content: " \\2022  ";
      color: #999 !important;
    }

    .resume .edit-language-fluency {
      font-weight: 400;
      color: #555 !important;
    }
    """
  end
end
