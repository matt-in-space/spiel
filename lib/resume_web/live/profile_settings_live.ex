defmodule ResumeWeb.ProfileSettingsLive do
  use ResumeWeb, :live_view

  alias Resume.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile_data = user.default_resume_data

    {:ok,
     assign(socket,
       user: user,
       profile_form: to_form(profile_data, as: "profile"),
       page_title: "Profile"
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
        <h1 class="text-2xl font-bold">Profile Settings</h1>
        <p class="text-sm opacity-70">
          This information appears on the contact section of your resumes.
        </p>

        <.form for={@profile_form} phx-change="validate" phx-submit="save">
          <.input field={@profile_form[:name]} label="Full Name" required />
          <.input field={@profile_form[:email]} label="Email" type="email" />
          <.input field={@profile_form[:phone]} label="Phone" type="tel" />
          <.input field={@profile_form[:location]} label="Location" placeholder="City, State" />
          <.input field={@profile_form[:website]} label="Website" type="url" placeholder="https://" />
          <.input
            field={@profile_form[:linkedin]}
            label="LinkedIn"
            placeholder="https://linkedin.com/in/..."
          />
          <.input field={@profile_form[:github]} label="GitHub" placeholder="https://github.com/..." />

          <div class="mt-6">
            <button type="submit" class="btn btn-primary">Save Changes</button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"profile" => params}, socket) do
    {:noreply, assign(socket, profile_form: to_form(params, as: "profile"))}
  end

  @impl true
  def handle_event("save", %{"profile" => params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_profile(user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(profile_form: to_form(params, as: "profile"))
         |> put_flash(:info, "Profile updated successfully.")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(profile_form: to_form(params, as: "profile"))
         |> put_flash(:error, "Please fill in your name.")}
    end
  end
end
