defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Resumes}
  alias ResumeWeb.ResumeTemplates.Default

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default
  }

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)
    template_mod = Map.get(@templates, resume.template, Default)

    {:ok,
     assign(socket,
       user: user,
       resume: resume,
       template_mod: template_mod,
       template_css: template_mod.css(),
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
            <.link href={~p"/resumes/#{@resume}/pdf"} class="btn btn-sm">
              <.icon name="hero-arrow-down-tray-micro" class="size-4" /> Download PDF
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

        <div
          :if={@resume.data}
          class="mx-auto max-w-[8.5in] bg-white shadow-lg rounded-sm p-[0.85in] print:shadow-none print:p-0"
        >
          {raw("<style>" <> @template_css <> "</style>")}
          <Default.render data={@resume.data} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("change_template", %{"template" => %{"template" => template}}, socket) do
    {:ok, resume} = Resumes.update_resume(socket.assigns.resume, %{template: template})
    template_mod = Map.get(@templates, template, Default)

    {:noreply,
     socket
     |> assign(
       resume: resume,
       template_mod: template_mod,
       template_css: template_mod.css(),
       template_form: to_form(%{"template" => template}, as: "template")
     )}
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
