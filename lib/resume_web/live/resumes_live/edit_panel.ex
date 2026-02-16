defmodule ResumeWeb.ResumesLive.EditPanel do
  use Phoenix.Component

  import ResumeWeb.CoreComponents

  attr :data_form, Phoenix.HTML.Form, required: true

  def edit_panel(assigns) do
    ~H"""
    <div class="space-y-2">
      <.summary_section form={@data_form} />
      <.contact_section form={@data_form} />
      <.work_experience_section form={@data_form} />
      <.education_section form={@data_form} />
      <.skills_section form={@data_form} />
      <.certifications_section form={@data_form} />
      <.projects_section form={@data_form} />
      <.publications_section form={@data_form} />
      <.volunteer_section form={@data_form} />
      <.languages_section form={@data_form} />
      <.awards_section form={@data_form} />
    </div>
    """
  end

  defp summary_section(assigns) do
    ~H"""
    <details id="section-summary" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">Summary</summary>
      <div class="collapse-content">
        <.input field={@form[:summary]} type="textarea" rows="4" />
      </div>
    </details>
    """
  end

  defp contact_section(assigns) do
    ~H"""
    <details id="section-contact" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">Contact Info</summary>
      <div class="collapse-content">
        <.inputs_for :let={ci} field={@form[:contact_info]}>
          <div class="grid grid-cols-2 gap-2">
            <.input field={ci[:name]} label="Name" />
            <.input field={ci[:email]} label="Email" type="email" />
            <.input field={ci[:phone]} label="Phone" type="tel" />
            <.input field={ci[:location]} label="Location" />
          </div>
          <div class="mt-2 space-y-2">
            <.inputs_for :let={w} field={ci[:websites]}>
              <div class="flex items-end gap-2">
                <div class="w-28">
                  <.input field={w[:type]} label="Type" />
                </div>
                <div class="flex-1">
                  <.input field={w[:url]} label="URL" type="url" />
                </div>
                <div class="w-28">
                  <.input field={w[:label]} label="Label" />
                </div>
              </div>
            </.inputs_for>
          </div>
        </.inputs_for>
      </div>
    </details>
    """
  end

  defp work_experience_section(assigns) do
    ~H"""
    <details id="section-work-experience" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Work Experience ({Enum.count(@form[:work_experience].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={we} field={@form[:work_experience]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{we.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="work_experience"
                phx-value-index={we.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={we[:role]} label="Role" />
              <.input field={we[:company]} label="Company" />
            </div>
            <.input field={we[:current]} type="checkbox" label="Current position" />
            <.flex_date_inputs label="Start Date" field={we[:start_date]} />
            <.flex_date_inputs label="End Date" field={we[:end_date]} />
            <.array_textarea
              field={we[:accomplishments]}
              label="Accomplishments (one per line)"
            />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="work_experience"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Work Experience
        </button>
      </div>
    </details>
    """
  end

  defp education_section(assigns) do
    ~H"""
    <details id="section-education" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Education ({Enum.count(@form[:education].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={ed} field={@form[:education]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{ed.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="education"
                phx-value-index={ed.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={ed[:institution]} label="Institution" />
              <.input field={ed[:degree]} label="Degree" />
            </div>
            <.input field={ed[:field]} label="Field of Study" />
            <.flex_date_inputs label="Start Date" field={ed[:start_date]} />
            <.flex_date_inputs label="End Date" field={ed[:end_date]} />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="education"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Education
        </button>
      </div>
    </details>
    """
  end

  defp skills_section(assigns) do
    ~H"""
    <details id="section-skills" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Skills ({Enum.count(@form[:skills].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={sg} field={@form[:skills]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{sg.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="skills"
                phx-value-index={sg.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <.input field={sg[:category]} label="Category" />
            <.array_textarea field={sg[:skills]} label="Skills (one per line)" />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="skills"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Skill Group
        </button>
      </div>
    </details>
    """
  end

  defp certifications_section(assigns) do
    ~H"""
    <details id="section-certifications" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Certifications ({Enum.count(@form[:certifications].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={cert} field={@form[:certifications]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{cert.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="certifications"
                phx-value-index={cert.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={cert[:name]} label="Name" />
              <.input field={cert[:issuer]} label="Issuer" />
            </div>
            <.flex_date_inputs label="Date" field={cert[:date]} />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="certifications"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Certification
        </button>
      </div>
    </details>
    """
  end

  defp projects_section(assigns) do
    ~H"""
    <details id="section-projects" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Projects ({Enum.count(@form[:projects].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={proj} field={@form[:projects]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{proj.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="projects"
                phx-value-index={proj.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={proj[:name]} label="Name" />
              <.input field={proj[:url]} label="URL" type="url" />
            </div>
            <.input field={proj[:description]} label="Description" type="textarea" rows="2" />
            <.array_textarea field={proj[:highlights]} label="Highlights (one per line)" />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="projects"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Project
        </button>
      </div>
    </details>
    """
  end

  defp publications_section(assigns) do
    ~H"""
    <details id="section-publications" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Publications ({Enum.count(@form[:publications].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={pub} field={@form[:publications]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{pub.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="publications"
                phx-value-index={pub.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={pub[:title]} label="Title" />
              <.input field={pub[:publisher]} label="Publisher" />
            </div>
            <.input field={pub[:url]} label="URL" type="url" />
            <.flex_date_inputs label="Date" field={pub[:date]} />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="publications"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Publication
        </button>
      </div>
    </details>
    """
  end

  defp volunteer_section(assigns) do
    ~H"""
    <details id="section-volunteer" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Volunteer Work ({Enum.count(@form[:volunteer_work].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={vol} field={@form[:volunteer_work]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{vol.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="volunteer_work"
                phx-value-index={vol.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={vol[:role]} label="Role" />
              <.input field={vol[:organization]} label="Organization" />
            </div>
            <.input field={vol[:description]} label="Description" type="textarea" rows="2" />
            <.flex_date_inputs label="Start Date" field={vol[:start_date]} />
            <.flex_date_inputs label="End Date" field={vol[:end_date]} />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="volunteer_work"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Volunteer Work
        </button>
      </div>
    </details>
    """
  end

  defp languages_section(assigns) do
    ~H"""
    <details id="section-languages" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Languages ({Enum.count(@form[:languages].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={lang} field={@form[:languages]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{lang.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="languages"
                phx-value-index={lang.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={lang[:name]} label="Language" />
              <.input field={lang[:fluency]} label="Fluency" />
            </div>
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="languages"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Language
        </button>
      </div>
    </details>
    """
  end

  defp awards_section(assigns) do
    ~H"""
    <details id="section-awards" class="collapse collapse-arrow bg-base-200">
      <summary class="collapse-title text-sm font-medium">
        Awards ({Enum.count(@form[:awards].value || [])})
      </summary>
      <div class="collapse-content space-y-4">
        <.inputs_for :let={award} field={@form[:awards]}>
          <div class="border border-base-300 rounded-lg p-3 space-y-2">
            <div class="flex justify-between items-start">
              <span class="text-xs font-medium text-base-content/60">
                #{award.index + 1}
              </span>
              <button
                type="button"
                phx-click="remove_item"
                phx-value-section="awards"
                phx-value-index={award.index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-3" />
              </button>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <.input field={award[:title]} label="Title" />
              <.input field={award[:issuer]} label="Issuer" />
            </div>
            <.input field={award[:summary]} label="Summary" type="textarea" rows="2" />
            <.flex_date_inputs label="Date" field={award[:date]} />
          </div>
        </.inputs_for>
        <button
          type="button"
          phx-click="add_item"
          phx-value-section="awards"
          class="btn btn-sm btn-outline btn-block"
        >
          <.icon name="hero-plus-micro" class="size-4" /> Add Award
        </button>
      </div>
    </details>
    """
  end

  defp flex_date_inputs(assigns) do
    ~H"""
    <div class="flex gap-2 items-end">
      <span class="label text-xs mb-2">{@label}:</span>
      <.inputs_for :let={d} field={@field}>
        <div class="w-20">
          <.input field={d[:year]} label="Year" type="number" />
        </div>
        <div class="w-20">
          <.input field={d[:month]} label="Month" type="number" />
        </div>
      </.inputs_for>
    </div>
    """
  end

  defp array_textarea(assigns) do
    value =
      case assigns.field.value do
        list when is_list(list) -> Enum.join(list, "\n")
        _ -> ""
      end

    assigns = assign(assigns, :text_value, value)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span class="label mb-1">{@label}</span>
        <textarea
          name={@field.name}
          rows="4"
          class="w-full textarea"
        >{@text_value}</textarea>
      </label>
    </div>
    """
  end
end
