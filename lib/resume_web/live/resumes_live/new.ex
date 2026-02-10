defmodule ResumeWeb.ResumesLive.New do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Resumes}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)

    {:ok,
     assign(socket,
       user: user,
       form:
         to_form(%{"title" => "", "job_posting_url" => "", "job_posting_text" => ""},
           as: "resume"
         ),
       generating: false,
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
          New Resume
          <:subtitle>Generate a resume from your profile and facts.</:subtitle>
        </.header>

        <div :if={@generating} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Generating your resume...</p>
        </div>

        <.form :if={!@generating} for={@form} phx-change="validate" phx-submit="generate">
          <div class="space-y-4">
            <.input
              field={@form[:title]}
              label="Title"
              placeholder="e.g. Software Engineer Resume"
              required
            />
            <.input
              field={@form[:job_posting_url]}
              label="Job Posting URL"
              type="url"
              placeholder="https://..."
            />
            <.input
              field={@form[:job_posting_text]}
              label="Job Posting Text"
              type="textarea"
              placeholder="Paste the job description here to tailor your resume..."
              rows="6"
            />

            <div class="flex gap-3">
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-sparkles-micro" class="size-4" /> Generate Resume
              </button>
              <.link navigate={~p"/resumes"} class="btn btn-ghost">Cancel</.link>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"resume" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "resume"))}
  end

  @impl true
  def handle_event("generate", %{"resume" => params}, socket) do
    title = String.trim(params["title"] || "")

    if title == "" do
      {:noreply, put_flash(socket, :error, "Title is required.")}
    else
      user = Accounts.get_user!(socket.assigns.user.id)

      opts =
        []
        |> maybe_add_opt(:job_posting_text, params["job_posting_text"])
        |> maybe_add_opt(:job_posting_url, params["job_posting_url"])

      task = Task.async(fn -> Resumes.generate_resume(user, title, opts) end)

      {:noreply,
       socket
       |> assign(generating: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :generate))}
    end
  end

  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, _key, ""), do: opts
  defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, String.trim(value))

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:generate, {:ok, resume}} ->
        {:noreply, push_navigate(socket, to: ~p"/resumes/#{resume}")}

      {:generate, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(generating: false)
         |> put_flash(:error, "Failed to generate resume. Please try again.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end
end
