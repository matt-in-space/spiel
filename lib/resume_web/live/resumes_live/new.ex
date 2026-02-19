defmodule ResumeWeb.ResumesLive.New do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, JobPostings, Resumes, Retry}

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
          <:subtitle>We'll build a resume from what we know about you.</:subtitle>
        </.header>

        <div :if={@generating} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Fetching job posting and generating your resume...</p>
        </div>

        <.form :if={!@generating} for={@form} phx-change="validate" phx-submit="generate">
          <div class="space-y-4">
            <.input
              field={@form[:title]}
              label="Title (optional)"
              placeholder="Auto-generated if left blank"
            />
            <.input
              field={@form[:job_posting_url]}
              label="Job Posting URL (optional)"
              type="url"
              placeholder="https://..."
            />
            <.input
              field={@form[:job_posting_text]}
              label="Job Description or Desired Role"
              type="textarea"
              placeholder="Paste a job description, or describe the kind of role you're targeting..."
              rows="6"
            />

            <div class="flex gap-3">
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-sparkles-micro" class="size-4" /> Generate Resume
              </button>
              <.link navigate={~p"/home"} class="btn btn-ghost">Cancel</.link>
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
    user = Accounts.get_user!(socket.assigns.user.id)

    title = non_blank(params["title"])
    url = non_blank(params["job_posting_url"])
    text = non_blank(params["job_posting_text"])

    task =
      Task.async(fn ->
        {job_posting_text, url_failed?} = resolve_job_posting_text(url, text)

        opts =
          []
          |> maybe_add_opt(:title, title)
          |> maybe_add_opt(:job_posting_text, job_posting_text)
          |> maybe_add_opt(:job_posting_url, url)

        case Retry.with_retry(fn -> Resumes.generate_resume(user, opts) end) do
          {:ok, resume} -> {:ok, resume, url_failed?}
          error -> error
        end
      end)

    {:noreply,
     socket
     |> assign(generating: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :generate))}
  end

  defp resolve_job_posting_text(nil, nil), do: {nil, false}
  defp resolve_job_posting_text(_url, text) when is_binary(text), do: {text, false}

  defp resolve_job_posting_text(url, nil) do
    case JobPostings.fetch_text(url) do
      {:ok, text} -> {text, false}
      {:error, _reason} -> {nil, true}
    end
  end

  defp non_blank(nil), do: nil

  defp non_blank(str) when is_binary(str) do
    case String.trim(str) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, value)

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:generate, {:ok, resume, true}} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Couldn't fetch the job posting URL. You can paste the text on the resume page."
         )
         |> push_navigate(to: ~p"/resumes/#{resume}")}

      {:generate, {:ok, resume, _}} ->
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
