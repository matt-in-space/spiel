defmodule ResumeWeb.ResumesLive.Index do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Resumes}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    resumes = Resumes.list_resumes_for_user(user.id)

    {:ok,
     socket
     |> assign(user: user, has_resumes?: resumes != [])
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
      <div class="space-y-6">
        <.header>
          Your Resumes
          <:actions>
            <.link navigate={~p"/resumes/new"} class="btn btn-primary btn-sm">
              <.icon name="hero-plus-micro" class="size-4" /> New Resume
            </.link>
          </:actions>
        </.header>

        <div :if={!@has_resumes?} class="text-center py-12 opacity-60">
          <.icon name="hero-document-text" class="size-12 mx-auto mb-3" />
          <p>No resumes yet. Create your first one!</p>
        </div>

        <div id="resumes" phx-update="stream" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div
            :for={{dom_id, resume} <- @streams.resumes}
            id={dom_id}
            class="card bg-base-200 shadow"
          >
            <div class="card-body">
              <h2 class="card-title text-base">
                {resume.title}
                <span
                  :if={resume.job_posting_text || resume.job_posting_url}
                  class="badge badge-accent badge-sm"
                >
                  Targeted
                </span>
              </h2>
              <p class="text-xs opacity-50">
                Created {Calendar.strftime(resume.inserted_at, "%b %d, %Y")}
              </p>
              <div class="card-actions justify-end mt-2">
                <.link navigate={~p"/resumes/#{resume}"} class="btn btn-ghost btn-sm">
                  View
                </.link>
                <button
                  phx-click="delete"
                  phx-value-id={resume.id}
                  data-confirm="Are you sure you want to delete this resume?"
                  class="btn btn-ghost btn-sm text-error"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resume = Resumes.get_user_resume!(socket.assigns.user.id, id)
    {:ok, _} = Resumes.delete_resume(resume)

    {:noreply,
     socket
     |> stream_delete(:resumes, resume)
     |> assign(has_resumes?: Resumes.list_resumes_for_user(socket.assigns.user.id) != [])}
  end
end
