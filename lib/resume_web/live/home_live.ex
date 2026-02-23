defmodule ResumeWeb.HomeLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Billing, JobPostings, Resumes}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    resumes = Resumes.list_resumes_for_user(user.id)

    fact_count = length(user.facts || [])

    {:ok,
     socket
     |> assign(
       user: user,
       show_onboarding_cta: fact_count == 0,
       show_tutorial: fact_count > 0 and Accounts.show_tutorial?(user, "home-tutorial"),
       profile_name: get_in(user.default_resume_data, ["name"]),
       fact_count: fact_count,
       directive_count: length(user.directives || []),
       form: to_form(%{"job_target" => ""}, as: "generate"),
       generating: false,
       upgrade_prompt: nil,
       pending_url: nil,
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
        <div :if={@show_onboarding_cta} class="card bg-base-200 border border-base-300">
          <div class="card-body text-center space-y-2">
            <.icon name="hero-microphone" class="size-10 text-primary mx-auto" />
            <h2 class="card-title justify-center">Finish your resume interview</h2>
            <p class="text-sm opacity-70">
              Tell us about your career so Spiel can generate better resumes for you.
            </p>
            <div class="card-actions justify-center mt-2">
              <.link navigate={~p"/onboarding"} class="btn btn-primary">
                Continue Setup
              </.link>
              <button phx-click="dismiss_onboarding" class="btn btn-ghost">Dismiss</button>
            </div>
          </div>
        </div>

        <div :if={!@show_onboarding_cta} class="text-center space-y-2">
          <h1 class="text-3xl font-semibold tracking-tight">What role are you targeting?</h1>
          <p class="text-sm opacity-70">
            Paste a job URL or description, or just describe the kind of role you're looking for.
          </p>
        </div>

        <div :if={@upgrade_prompt} class="alert alert-warning mb-4">
          <.icon name="hero-lock-closed-micro" class="size-5" />
          <span>{@upgrade_prompt}</span>
          <.link navigate={~p"/billing"} class="btn btn-sm btn-primary">Get Unlimited Access</.link>
        </div>

        <div :if={!@show_onboarding_cta && @generating} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Fetching job posting...</p>
        </div>

        <.form
          :if={!@show_onboarding_cta && !@generating}
          for={@form}
          phx-change="validate"
          phx-submit="generate"
        >
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

      <.tutorial
        id="home-tutorial"
        show={@show_tutorial}
        steps={[
          %{
            target: "#generate_job_target",
            message:
              "Describe a job you're targeting or paste a job posting URL to generate a tailored resume.",
            position: "bottom"
          },
          %{
            target: "#resumes",
            message: "Your generated resumes appear here. Click one to view and edit it.",
            position: "top"
          },
          %{
            target: "a[href='/profile']",
            message: "Visit your profile to update your career details and rules.",
            position: "bottom"
          }
        ]}
      />
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("dismiss_tutorial", %{"id" => id}, socket) do
    Accounts.dismiss_tutorial(socket.assigns.user, id)
    {:noreply, assign(socket, show_tutorial: false)}
  end

  @impl true
  def handle_event("dismiss_onboarding", _params, socket) do
    {:noreply, assign(socket, show_onboarding_cta: false)}
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

      case Billing.check_allowance(user, :generation) do
        :ok ->
          if String.starts_with?(input, "http") do
            # URL provided — fetch async, then create record + redirect
            url = input |> String.split("\n") |> List.first() |> String.trim()
            task = Task.async(fn -> JobPostings.fetch_text(url) end)

            {:noreply,
             socket
             |> assign(generating: true, pending_url: url)
             |> update(:task_refs, &Map.put(&1, task.ref, :fetch_url))}
          else
            # Plain text — create record and redirect immediately
            create_and_redirect(socket, input, nil)
          end

        {:error, :limit_reached, message} ->
          {:noreply, assign(socket, generating: false, upgrade_prompt: message)}
      end
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
      {:fetch_url, {:ok, text}} ->
        url = socket.assigns.pending_url
        create_and_redirect(socket, text, url)

      {:fetch_url, {:error, _reason}} ->
        # URL fetch failed — create record without text, redirect with warning
        url = socket.assigns.pending_url

        create_and_redirect(
          socket,
          nil,
          url,
          "Couldn't fetch that URL. The resume was generated without it."
        )

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  defp create_and_redirect(socket, job_posting_text, job_posting_url, flash_error \\ nil) do
    title = Resumes.fallback_title()

    case Resumes.create_resume(%{
           title: title,
           user_id: socket.assigns.user.id,
           template: socket.assigns.user.default_resume_template,
           job_posting_text: job_posting_text,
           job_posting_url: job_posting_url
         }) do
      {:ok, resume} ->
        socket = if flash_error, do: put_flash(socket, :error, flash_error), else: socket
        {:noreply, push_navigate(socket, to: ~p"/resumes/#{resume}")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(generating: false)
         |> put_flash(:error, "Failed to create resume. Please try again.")}
    end
  end
end
