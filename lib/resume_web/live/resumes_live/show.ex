defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Resumes}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)

    {:ok,
     assign(socket,
       user: user,
       resume: resume,
       template_form: to_form(%{"template" => resume.template}, as: "template"),
       regenerating: false,
       task_refs: %{}
     )}
  end

  defp get_user(socket, session) do
    case socket.assigns[:current_scope] do
      %{user: user} when not is_nil(user) ->
        user

      _ ->
        token = session["user_token"]
        {user, _inserted_at} = Accounts.get_user_by_session_token(token)
        user
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <.header>
          {@resume.title}
          <:subtitle>
            <span
              :if={@resume.job_posting_text || @resume.job_posting_url}
              class="badge badge-accent badge-sm"
            >
              Targeted
            </span>
            Created {Calendar.strftime(@resume.inserted_at, "%b %d, %Y")}
          </:subtitle>
          <:actions>
            <.link navigate={~p"/resumes"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left-micro" class="size-4" /> Back
            </.link>
            <button
              phx-click="regenerate"
              disabled={@regenerating}
              class="btn btn-sm"
            >
              <span :if={@regenerating} class="loading loading-spinner loading-xs"></span>
              <.icon :if={!@regenerating} name="hero-arrow-path-micro" class="size-4" /> Regenerate
            </button>
            <button
              phx-click="delete"
              data-confirm="Are you sure you want to delete this resume?"
              class="btn btn-ghost btn-sm text-error"
            >
              Delete
            </button>
          </:actions>
        </.header>

        <div class="flex items-center gap-3">
          <.form for={@template_form} phx-change="change_template" class="flex items-center gap-2">
            <label class="text-sm font-medium">Template:</label>
            <.input
              field={@template_form[:template]}
              type="select"
              options={[{"Default", "default"}]}
            />
          </.form>
        </div>

        <div :if={@resume.data} class="space-y-8">
          <.contact_info contact={@resume.data.contact_info} />
          <.summary_section summary={@resume.data.summary} />
          <.work_experience_section experiences={@resume.data.work_experience} />
          <.education_section entries={@resume.data.education} />
          <.skills_section groups={@resume.data.skills} />
          <.certifications_section certs={@resume.data.certifications} />
          <.projects_section projects={@resume.data.projects} />
          <.publications_section pubs={@resume.data.publications} />
          <.volunteer_section entries={@resume.data.volunteer_work} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp contact_info(%{contact: nil} = assigns), do: ~H""

  defp contact_info(assigns) do
    ~H"""
    <section>
      <h2 class="text-2xl font-bold">{@contact.name}</h2>
      <div class="flex flex-wrap gap-x-4 gap-y-1 text-sm opacity-70 mt-1">
        <span :if={@contact.email}>{@contact.email}</span>
        <span :if={@contact.phone}>{@contact.phone}</span>
        <span :if={@contact.location}>{@contact.location}</span>
        <span :if={@contact.website}>
          <.link href={@contact.website} target="_blank" class="link">{@contact.website}</.link>
        </span>
        <span :if={@contact.linkedin}>
          <.link href={@contact.linkedin} target="_blank" class="link">LinkedIn</.link>
        </span>
        <span :if={@contact.github}>
          <.link href={@contact.github} target="_blank" class="link">GitHub</.link>
        </span>
      </div>
    </section>
    """
  end

  defp summary_section(%{summary: nil} = assigns), do: ~H""
  defp summary_section(%{summary: ""} = assigns), do: ~H""

  defp summary_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-2">Summary</h3>
      <p class="text-sm">{@summary}</p>
    </section>
    """
  end

  defp work_experience_section(%{experiences: []} = assigns), do: ~H""

  defp work_experience_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Work Experience</h3>
      <div class="space-y-4">
        <div :for={exp <- @experiences}>
          <div class="flex justify-between items-baseline">
            <h4 class="font-medium">{exp.role}</h4>
            <span class="text-xs opacity-50">
              {format_date_range(exp.start_date, exp.end_date, exp.current)}
            </span>
          </div>
          <p class="text-sm opacity-70">{exp.company}</p>
          <ul :if={exp.accomplishments != []} class="list-disc list-inside text-sm mt-1 space-y-0.5">
            <li :for={item <- exp.accomplishments}>{item}</li>
          </ul>
        </div>
      </div>
    </section>
    """
  end

  defp education_section(%{entries: []} = assigns), do: ~H""

  defp education_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Education</h3>
      <div class="space-y-3">
        <div :for={edu <- @entries}>
          <div class="flex justify-between items-baseline">
            <h4 class="font-medium">{edu.degree} in {edu.field}</h4>
            <span class="text-xs opacity-50">
              {format_date_range(edu.start_date, edu.end_date, false)}
            </span>
          </div>
          <p class="text-sm opacity-70">{edu.institution}</p>
        </div>
      </div>
    </section>
    """
  end

  defp skills_section(%{groups: []} = assigns), do: ~H""

  defp skills_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Skills</h3>
      <div class="space-y-2">
        <div :for={group <- @groups} class="flex flex-wrap items-center gap-2">
          <span class="text-sm font-medium">{group.category}:</span>
          <span :for={skill <- group.skills} class="badge badge-outline badge-sm">{skill}</span>
        </div>
      </div>
    </section>
    """
  end

  defp certifications_section(%{certs: []} = assigns), do: ~H""

  defp certifications_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Certifications</h3>
      <div class="space-y-2">
        <div :for={cert <- @certs} class="flex justify-between items-baseline">
          <div>
            <span class="font-medium text-sm">{cert.name}</span>
            <span :if={cert.issuer} class="text-sm opacity-70"> —  {cert.issuer}</span>
          </div>
          <span :if={cert.date} class="text-xs opacity-50">{format_flex_date(cert.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp projects_section(%{projects: []} = assigns), do: ~H""

  defp projects_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Projects</h3>
      <div class="space-y-3">
        <div :for={proj <- @projects}>
          <h4 class="font-medium text-sm">
            {proj.name}
            <.link :if={proj.url} href={proj.url} target="_blank" class="link text-xs ml-1">
              {proj.url}
            </.link>
          </h4>
          <p :if={proj.description} class="text-sm opacity-70">{proj.description}</p>
          <ul :if={proj.highlights != []} class="list-disc list-inside text-sm mt-1 space-y-0.5">
            <li :for={item <- proj.highlights}>{item}</li>
          </ul>
        </div>
      </div>
    </section>
    """
  end

  defp publications_section(%{pubs: []} = assigns), do: ~H""

  defp publications_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Publications</h3>
      <div class="space-y-2">
        <div :for={pub <- @pubs} class="flex justify-between items-baseline">
          <div>
            <span class="font-medium text-sm">{pub.title}</span>
            <span :if={pub.publisher} class="text-sm opacity-70"> —  {pub.publisher}</span>
            <.link :if={pub.url} href={pub.url} target="_blank" class="link text-xs ml-1">Link</.link>
          </div>
          <span :if={pub.date} class="text-xs opacity-50">{format_flex_date(pub.date)}</span>
        </div>
      </div>
    </section>
    """
  end

  defp volunteer_section(%{entries: []} = assigns), do: ~H""

  defp volunteer_section(assigns) do
    ~H"""
    <section>
      <h3 class="text-lg font-semibold border-b border-base-300 pb-1 mb-3">Volunteer Work</h3>
      <div class="space-y-3">
        <div :for={vol <- @entries}>
          <div class="flex justify-between items-baseline">
            <h4 class="font-medium text-sm">{vol.role}</h4>
            <span class="text-xs opacity-50">
              {format_date_range(vol.start_date, vol.end_date, false)}
            </span>
          </div>
          <p class="text-sm opacity-70">{vol.organization}</p>
          <p :if={vol.description} class="text-sm mt-1">{vol.description}</p>
        </div>
      </div>
    </section>
    """
  end

  defp format_flex_date(nil), do: ""

  defp format_flex_date(%{year: year, month: month}) when is_integer(month) do
    month_name = Calendar.strftime(%Date{year: year, month: month, day: 1}, "%b")
    "#{month_name} #{year}"
  end

  defp format_flex_date(%{year: year}), do: "#{year}"

  defp format_date_range(start_date, end_date, current) do
    start_str = format_flex_date(start_date)
    end_str = if current, do: "Present", else: format_flex_date(end_date)

    case {start_str, end_str} do
      {"", ""} -> ""
      {s, ""} -> s
      {"", e} -> e
      {s, e} -> "#{s} — #{e}"
    end
  end

  @impl true
  def handle_event("change_template", %{"template" => %{"template" => template}}, socket) do
    {:ok, resume} = Resumes.update_resume(socket.assigns.resume, %{template: template})

    {:noreply,
     socket
     |> assign(resume: resume, template_form: to_form(%{"template" => template}, as: "template"))}
  end

  @impl true
  def handle_event("regenerate", _params, socket) do
    user = Accounts.get_user!(socket.assigns.user.id)
    resume = socket.assigns.resume

    task = Task.async(fn -> Resumes.regenerate_resume(resume, user) end)

    {:noreply,
     socket
     |> assign(regenerating: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :regenerate))}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Resumes.delete_resume(socket.assigns.resume)

    {:noreply,
     socket
     |> put_flash(:info, "Resume deleted.")
     |> push_navigate(to: ~p"/resumes")}
  end

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:regenerate, {:ok, resume}} ->
        {:noreply,
         socket
         |> assign(resume: resume, regenerating: false)
         |> put_flash(:info, "Resume regenerated.")}

      {:regenerate, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(regenerating: false)
         |> put_flash(:error, "Failed to regenerate resume. Please try again.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end
end
