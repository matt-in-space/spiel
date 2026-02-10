defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, JobPostings, Resumes}
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
       targeting_form: build_targeting_form(resume),
       fetching_url: false,
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

        <details class="collapse collapse-arrow bg-base-200">
          <summary class="collapse-title text-sm font-medium">
            Job Targeting
            <span
              :if={@resume.job_posting_text || @resume.job_posting_url}
              class="badge badge-accent badge-xs ml-2"
            >
              Active
            </span>
          </summary>
          <div class="collapse-content">
            <.form for={@targeting_form} phx-submit="save_targeting" phx-change="validate_targeting">
              <div class="space-y-3">
                <div class="flex gap-2 items-end">
                  <div class="flex-1">
                    <.input
                      field={@targeting_form[:job_posting_url]}
                      label="Job Posting URL"
                      type="url"
                      placeholder="https://..."
                    />
                  </div>
                  <button
                    type="button"
                    phx-click="fetch_url"
                    disabled={@fetching_url}
                    class="btn btn-sm btn-outline mb-2"
                  >
                    <span :if={@fetching_url} class="loading loading-spinner loading-xs"></span>
                    <.icon :if={!@fetching_url} name="hero-arrow-down-tray-micro" class="size-4" />
                    Fetch
                  </button>
                </div>
                <.input
                  field={@targeting_form[:job_posting_text]}
                  label="Job Posting Text"
                  type="textarea"
                  placeholder="Paste the job description here, or fetch from URL above..."
                  rows="4"
                />
                <div class="flex gap-2">
                  <button type="submit" class="btn btn-sm btn-primary">Save Targeting</button>
                  <button
                    :if={@resume.job_posting_text || @resume.job_posting_url}
                    type="button"
                    phx-click="clear_targeting"
                    class="btn btn-sm btn-ghost"
                  >
                    Clear
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </details>

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
  def handle_event("validate_targeting", %{"targeting" => params}, socket) do
    {:noreply, assign(socket, targeting_form: to_form(params, as: "targeting"))}
  end

  @impl true
  def handle_event("save_targeting", %{"targeting" => params}, socket) do
    url = non_blank(params["job_posting_url"])
    text = non_blank(params["job_posting_text"])

    case Resumes.update_resume(socket.assigns.resume, %{
           job_posting_url: url,
           job_posting_text: text
         }) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(resume: resume, targeting_form: build_targeting_form(resume))
         |> put_flash(:info, "Job targeting saved.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save targeting.")}
    end
  end

  @impl true
  def handle_event("fetch_url", _params, socket) do
    url =
      socket.assigns.targeting_form.params["job_posting_url"]
      |> non_blank()

    if url do
      task = Task.async(fn -> JobPostings.fetch_text(url) end)

      {:noreply,
       socket
       |> assign(fetching_url: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :fetch_url))}
    else
      {:noreply, put_flash(socket, :error, "Enter a URL first.")}
    end
  end

  @impl true
  def handle_event("clear_targeting", _params, socket) do
    case Resumes.update_resume(socket.assigns.resume, %{
           job_posting_url: nil,
           job_posting_text: nil
         }) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(resume: resume, targeting_form: build_targeting_form(resume))
         |> put_flash(:info, "Job targeting cleared.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to clear targeting.")}
    end
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

      {:fetch_url, {:ok, text}} ->
        params = Map.put(socket.assigns.targeting_form.params, "job_posting_text", text)

        {:noreply,
         socket
         |> assign(fetching_url: false, targeting_form: to_form(params, as: "targeting"))
         |> put_flash(:info, "Job posting content fetched.")}

      {:fetch_url, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(fetching_url: false)
         |> put_flash(:error, "Failed to fetch job posting. Try pasting the text instead.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  defp build_targeting_form(resume) do
    to_form(
      %{
        "job_posting_url" => resume.job_posting_url || "",
        "job_posting_text" => resume.job_posting_text || ""
      },
      as: "targeting"
    )
  end

  defp non_blank(nil), do: nil

  defp non_blank(str) when is_binary(str) do
    case String.trim(str) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
