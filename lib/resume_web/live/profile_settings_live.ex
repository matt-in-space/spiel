defmodule ResumeWeb.ProfileSettingsLive do
  use ResumeWeb, :live_view

  alias Resume.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile_data = user.default_resume_data
    career_goal = profile_data["career_goal"]

    {:ok,
     assign(socket,
       user: user,
       career_goal: career_goal,
       profile_form: to_form(profile_data, as: "profile"),
       facts: user.facts || [],
       editing_index: nil,
       edit_form: to_form(%{"text" => ""}, as: "edit"),
       new_fact_form: to_form(%{"text" => ""}, as: "new_fact"),
       directives: user.directives || [],
       new_directive_form: to_form(%{"text" => ""}, as: "new_directive"),
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

        <div :if={@career_goal} class="card bg-base-200 p-4">
          <h2 class="text-sm font-semibold opacity-70 mb-1">Career Goal</h2>
          <p class="text-sm">{@career_goal}</p>
          <p class="text-xs opacity-50 mt-2">
            Extracted from your interview. Re-do the interview to update.
          </p>
        </div>

        <div class="divider"></div>

        <div class="space-y-4">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-bold">Your Facts</h2>
            <span class="badge badge-neutral">{length(@facts)}</span>
          </div>

          <div :if={@facts == []} class="text-sm opacity-50">
            No facts yet. Add some below, or record yourself talking about your experience.
          </div>

          <ul :if={@facts != []} class="space-y-2">
            <li
              :for={{fact, index} <- Enum.with_index(@facts)}
              class="card bg-base-200 p-3 flex flex-row items-center gap-3"
            >
              <div :if={@editing_index != index} class="flex-1">{fact}</div>
              <div :if={@editing_index != index} class="flex gap-1">
                <button
                  type="button"
                  phx-click="edit_fact"
                  phx-value-index={index}
                  class="btn btn-ghost btn-xs"
                  aria-label="Edit fact"
                >
                  <.icon name="hero-pencil-square" class="size-4" />
                </button>
                <button
                  type="button"
                  phx-click="delete_fact"
                  phx-value-index={index}
                  class="btn btn-ghost btn-xs"
                  aria-label="Delete fact"
                >
                  <.icon name="hero-x-mark" class="size-4" />
                </button>
              </div>

              <.form
                :if={@editing_index == index}
                for={@edit_form}
                phx-change="update_edit"
                phx-submit="save_edit"
                class="flex-1 flex items-center gap-2"
              >
                <.input field={@edit_form[:text]} class="flex-1" />
                <button type="submit" class="btn btn-ghost btn-xs" aria-label="Save edit">
                  <.icon name="hero-check" class="size-4" />
                </button>
                <button
                  type="button"
                  phx-click="cancel_edit"
                  class="btn btn-ghost btn-xs"
                  aria-label="Cancel edit"
                >
                  <.icon name="hero-x-mark" class="size-4" />
                </button>
              </.form>
            </li>
          </ul>

          <.form
            for={@new_fact_form}
            phx-change="validate_new_fact"
            phx-submit="add_fact"
            class="flex items-center gap-2"
          >
            <.input field={@new_fact_form[:text]} placeholder="Add a new fact..." class="flex-1" />
            <button type="submit" class="btn btn-primary btn-sm">Add</button>
          </.form>
        </div>

        <div class="divider"></div>

        <div class="space-y-4">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-bold">Your Directives</h2>
            <span class="badge badge-neutral">{length(@directives)}</span>
          </div>

          <div :if={@directives == []} class="text-sm opacity-50">
            No directives yet. Directives are standing instructions that apply to all your resumes,
            like "always emphasize leadership" or "keep it to one page."
          </div>

          <ul :if={@directives != []} class="space-y-2">
            <li
              :for={{directive, index} <- Enum.with_index(@directives)}
              class="card bg-base-200 p-3 flex flex-row items-center gap-3"
            >
              <div class="flex-1">{directive}</div>
              <button
                type="button"
                phx-click="delete_directive"
                phx-value-index={index}
                class="btn btn-ghost btn-xs"
                aria-label="Delete directive"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </li>
          </ul>

          <.form
            for={@new_directive_form}
            phx-change="validate_new_directive"
            phx-submit="add_directive"
            class="flex items-center gap-2"
          >
            <.input
              field={@new_directive_form[:text]}
              placeholder="Add a directive, e.g. 'Always emphasize leadership'"
              class="flex-1"
            />
            <button type="submit" class="btn btn-primary btn-sm">Add</button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("edit_fact", %{"index" => index}, socket) do
    index = String.to_integer(index)
    text = Enum.at(socket.assigns.facts, index)

    {:noreply,
     assign(socket, editing_index: index, edit_form: to_form(%{"text" => text}, as: "edit"))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_index: nil)}
  end

  @impl true
  def handle_event("update_edit", %{"edit" => params}, socket) do
    {:noreply, assign(socket, edit_form: to_form(params, as: "edit"))}
  end

  @impl true
  def handle_event("save_edit", %{"edit" => %{"text" => text}}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      facts = List.replace_at(socket.assigns.facts, socket.assigns.editing_index, text)
      {:ok, user} = Accounts.update_user_facts(socket.assigns.user, facts)
      {:noreply, assign(socket, facts: user.facts, editing_index: nil, user: user)}
    end
  end

  @impl true
  def handle_event("delete_fact", %{"index" => index}, socket) do
    index = String.to_integer(index)
    facts = List.delete_at(socket.assigns.facts, index)
    {:ok, user} = Accounts.update_user_facts(socket.assigns.user, facts)
    {:noreply, assign(socket, facts: user.facts, user: user)}
  end

  @impl true
  def handle_event("validate_new_fact", %{"new_fact" => params}, socket) do
    {:noreply, assign(socket, new_fact_form: to_form(params, as: "new_fact"))}
  end

  @impl true
  def handle_event("add_fact", %{"new_fact" => %{"text" => text}}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      facts = socket.assigns.facts ++ [text]
      {:ok, user} = Accounts.update_user_facts(socket.assigns.user, facts)

      {:noreply,
       assign(socket,
         facts: user.facts,
         user: user,
         new_fact_form: to_form(%{"text" => ""}, as: "new_fact")
       )}
    end
  end

  # Directive events

  @impl true
  def handle_event("validate_new_directive", %{"new_directive" => params}, socket) do
    {:noreply, assign(socket, new_directive_form: to_form(params, as: "new_directive"))}
  end

  @impl true
  def handle_event("add_directive", %{"new_directive" => %{"text" => text}}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      directives = socket.assigns.directives ++ [text]
      {:ok, user} = Accounts.update_user_directives(socket.assigns.user, directives)

      {:noreply,
       assign(socket,
         directives: user.directives,
         user: user,
         new_directive_form: to_form(%{"text" => ""}, as: "new_directive")
       )}
    end
  end

  @impl true
  def handle_event("delete_directive", %{"index" => index}, socket) do
    index = String.to_integer(index)
    directives = List.delete_at(socket.assigns.directives, index)
    {:ok, user} = Accounts.update_user_directives(socket.assigns.user, directives)
    {:noreply, assign(socket, directives: user.directives, user: user)}
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
