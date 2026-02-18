defmodule ResumeWeb.HomeLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, JobPostings, Resumes, Retry}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    resumes = Resumes.list_resumes_for_user(user.id)

    {:ok,
     socket
     |> assign(
       user: user,
       profile_name: get_in(user.default_resume_data, ["name"]),
       fact_count: length(user.facts || []),
       directive_count: length(user.directives || []),
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
        <div class="flex items-center justify-between">
          <div :if={@profile_name}>
            <p class="font-medium text-sm">{@profile_name}</p>
            <p class="text-xs opacity-50">
              {ngettext("%{count} detail", "%{count} details", @fact_count)} · {ngettext(
                "%{count} rule",
                "%{count} rules",
                @directive_count
              )}
            </p>
          </div>
          <p :if={!@profile_name} class="text-sm opacity-70">
            Set up your profile to generate better resumes
          </p>
          <.link navigate={~p"/profile"} class="btn btn-ghost btn-xs">
            {if @profile_name, do: "Edit Profile", else: "Set up"}
          </.link>
        </div>

        <div class="text-center space-y-2">
          <h1 class="text-3xl font-semibold tracking-tight">What role are you targeting?</h1>
          <p class="text-sm opacity-70">
            Paste a job URL or description, or just describe the kind of role you're looking for.
          </p>
        </div>

        <div :if={@generating} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Generating your resume...</p>
        </div>

        <.form :if={!@generating} for={@form} phx-change="validate" phx-submit="generate">
          <textarea
            id={@form[:job_target].id}
            name={@form[:job_target].name}
            placeholder="e.g. https://..., paste a job description, or describe your desired role"
            rows="4"
            phx-hook="AutoGrow"
            class="w-full textarea resize-none overflow-y-auto"
            style="max-height: 40vh"
          >{Phoenix.HTML.Form.normalize_value("textarea", @form[:job_target].value)}</textarea>
          <div class="mt-4">
            <button type="submit" class="btn btn-primary w-full">
              <.icon name="hero-sparkles-micro" class="size-4" /> Generate Resume
            </button>
          </div>
        </.form>

        <div class="divider">Your Resumes</div>

        <div id="resumes" phx-update="stream" class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            :for={{dom_id, resume} <- @streams.resumes}
            id={dom_id}
            class="card bg-base-200 border border-base-300 hover:border-base-content/20 transition-colors relative p-3 flex flex-col gap-2"
          >
            <.link navigate={~p"/resumes/#{resume}"} class="after:absolute after:inset-0">
              <h2 class="font-medium text-sm pr-6">
                {resume.title}
              </h2>
              <div class="flex items-center gap-1.5 mt-1">
                <span class="text-xs opacity-50">
                  {Calendar.strftime(resume.inserted_at, "%b %d, %Y")}
                </span>
                <span
                  :if={resume.job_posting_text || resume.job_posting_url}
                  class="badge badge-accent badge-xs"
                >
                  Targeted
                </span>
              </div>
            </.link>
            <button
              phx-click="delete"
              phx-value-id={resume.id}
              data-confirm="Delete this resume?"
              class="btn btn-ghost btn-xs text-error absolute top-2 right-2 z-10"
            >
              <.icon name="hero-trash-micro" class="size-3.5" />
            </button>
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
          {job_posting_text, job_posting_url, url_failed?} = resolve_input(input)
          title = generate_title(input)

          opts =
            []
            |> maybe_add_opt(:job_posting_text, job_posting_text)
            |> maybe_add_opt(:job_posting_url, job_posting_url)

          case Retry.with_retry(fn -> Resumes.generate_resume(user, title, opts) end) do
            {:ok, resume} -> {:ok, resume, url_failed?}
            error -> error
          end
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
      {:generate, {:ok, resume, true}} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Couldn't fetch that URL. Try pasting the job description text instead."
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

  defp resolve_input(input) do
    if String.starts_with?(input, "http") do
      url = input |> String.split("\n") |> List.first() |> String.trim()

      case JobPostings.fetch_text(url) do
        {:ok, text} -> {text, url, false}
        {:error, _} -> {nil, url, true}
      end
    else
      {input, nil, false}
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
