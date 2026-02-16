defmodule ResumeWeb.HomeLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, JobPostings, Resumes}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    resumes = Resumes.list_resumes_for_user(user.id)

    {:ok,
     socket
     |> assign(
       user: user,
       form: to_form(%{"job_target" => ""}, as: "generate"),
       generating: false,
       task_refs: %{}
     )
     |> stream(:resumes, resumes)}
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
      <div class="space-y-8 max-w-2xl mx-auto">
        <div class="text-center space-y-2">
          <h1 class="text-3xl font-semibold tracking-tight">What role are you targeting?</h1>
          <p class="text-sm opacity-70">
            Paste a job URL or description, or describe the kind of role you want.
          </p>
        </div>

        <div :if={@generating} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Generating your resume...</p>
        </div>

        <.form :if={!@generating} for={@form} phx-change="validate" phx-submit="generate">
          <.input
            field={@form[:job_target]}
            type="textarea"
            placeholder="e.g. https://..., paste a job description, or describe your desired role"
            rows="4"
          />
          <div class="mt-4">
            <button type="submit" class="btn btn-primary w-full">
              <.icon name="hero-sparkles-micro" class="size-4" /> Generate Resume
            </button>
          </div>
        </.form>

        <div class="divider">Your Resumes</div>

        <div id="resumes" phx-update="stream" class="space-y-3">
          <div
            :for={{dom_id, resume} <- @streams.resumes}
            id={dom_id}
            class="card bg-base-200 border border-base-300 hover:border-base-content/20 transition-colors relative"
          >
            <div class="card-body py-3 px-4 flex-row items-center justify-between">
              <.link navigate={~p"/resumes/#{resume}"} class="after:absolute after:inset-0">
                <h2 class="font-medium text-sm">
                  {resume.title}
                  <span
                    :if={resume.job_posting_text || resume.job_posting_url}
                    class="badge badge-accent badge-xs ml-1"
                  >
                    Targeted
                  </span>
                </h2>
                <p class="text-xs opacity-50">
                  {Calendar.strftime(resume.inserted_at, "%b %d, %Y")}
                </p>
              </.link>
              <button
                phx-click="delete"
                phx-value-id={resume.id}
                data-confirm="Delete this resume?"
                class="btn btn-ghost btn-xs text-error relative z-10"
              >
                <.icon name="hero-trash-micro" class="size-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"generate" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "generate"))}
  end

  @impl true
  def handle_event("generate", %{"generate" => %{"job_target" => input}}, socket) do
    input = String.trim(input)

    if input == "" do
      {:noreply, put_flash(socket, :error, "Please describe the job you're applying for.")}
    else
      user = Accounts.get_user!(socket.assigns.user.id)

      task =
        Task.async(fn ->
          {job_posting_text, job_posting_url} = resolve_input(input)
          title = generate_title(input)

          opts =
            []
            |> maybe_add_opt(:job_posting_text, job_posting_text)
            |> maybe_add_opt(:job_posting_url, job_posting_url)

          Resumes.generate_resume(user, title, opts)
        end)

      {:noreply,
       socket
       |> assign(generating: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :generate))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resume = Resumes.get_user_resume!(socket.assigns.user.id, id)
    {:ok, _} = Resumes.delete_resume(resume)
    {:noreply, stream_delete(socket, :resumes, resume)}
  end

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

  defp resolve_input(input) do
    if String.starts_with?(input, "http") do
      url = input |> String.split("\n") |> List.first() |> String.trim()

      case JobPostings.fetch_text(url) do
        {:ok, text} -> {text, url}
        {:error, _} -> {input, url}
      end
    else
      {input, nil}
    end
  end

  defp generate_title(input) do
    first_line = input |> String.split("\n") |> List.first() |> String.trim()

    if String.starts_with?(first_line, "http") do
      "Resume - #{Calendar.strftime(DateTime.utc_now(), "%b %d, %Y")}"
    else
      first_line
      |> String.replace(~r/^(a job (?:as|for|at|in)|looking for|applying (?:for|to))\s+/i, "")
      |> String.slice(0, 60)
    end
  end

  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, value)
end
