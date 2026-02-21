defmodule ResumeWeb.ProfileSettingsLive do
  use ResumeWeb, :live_view

  alias Resume.Accounts

  @website_types [
    {"LinkedIn", "linkedin"},
    {"GitHub", "github"},
    {"Custom", "custom"}
  ]

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile_data = user.default_resume_data
    career_goal = profile_data["career_goal"]
    websites = profile_data["websites"] || []

    show_tutorial = Accounts.show_tutorial?(user, "profile-tutorial")

    {:ok,
     assign(socket,
       user: user,
       career_goal: career_goal,
       websites: websites,
       website_types: @website_types,
       add_website_type: "linkedin",
       profile_form: to_form(profile_data, as: "profile"),
       career_goal_form: to_form(%{"instruction" => ""}, as: "career_goal"),
       processing_career_goal: false,
       facts: user.facts || [],
       directives: user.directives || [],
       active_tab: if(show_tutorial, do: :details_rules, else: :profile),
       show_tutorial: show_tutorial,
       editing_item: nil,
       item_form: to_form(%{"text" => ""}, as: "item"),
       filter: "",
       task_refs: %{},
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
  def handle_params(%{"tab" => "details_rules"}, _uri, socket) do
    {:noreply, assign(socket, active_tab: :details_rules)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: "Profile"}]}>
      <div class="space-y-6">
        <h1 class="text-2xl font-semibold tracking-tight">Profile Settings</h1>

        <div role="tablist" class="tabs tabs-bordered">
          <button
            role="tab"
            class={"tab #{if @active_tab == :profile, do: "tab-active"}"}
            phx-click="switch_tab"
            phx-value-tab="profile"
          >
            Profile
          </button>
          <button
            role="tab"
            class={"tab #{if @active_tab == :details_rules, do: "tab-active"}"}
            phx-click="switch_tab"
            phx-value-tab="details_rules"
          >
            Details & Rules
            <span class="badge badge-sm ml-1">{length(@facts) + length(@directives)}</span>
          </button>
        </div>

        <%!-- Profile Tab --%>
        <div :if={@active_tab == :profile} class="space-y-6">
          <p class="text-sm opacity-70">
            This information appears on the contact section of your resumes.
          </p>

          <.form for={@profile_form} phx-change="validate" phx-submit="save">
            <.input field={@profile_form[:name]} label="Full Name" required />
            <.input field={@profile_form[:email]} label="Email" type="email" />
            <.input field={@profile_form[:phone]} label="Phone" type="tel" />
            <.input field={@profile_form[:location]} label="Location" placeholder="City, State" />

            <div class="mt-4 space-y-3">
              <label class="label">Websites</label>
              <div :for={{w, i} <- Enum.with_index(@websites)} class="flex items-end gap-2">
                <span class="badge badge-sm badge-outline self-center">
                  {website_type_label(w["type"])}
                </span>
                <input type="hidden" name={"profile[websites][#{i}][type]"} value={w["type"]} />
                <input
                  :if={w["type"] in ["custom", "website"]}
                  type="text"
                  name={"profile[websites][#{i}][label]"}
                  value={w["label"]}
                  placeholder="Label"
                  class="input input-bordered input-sm w-28"
                />
                <div class="flex-1">
                  <input
                    type="url"
                    name={"profile[websites][#{i}][url]"}
                    value={w["url"]}
                    placeholder="https://..."
                    class="input input-bordered input-sm w-full"
                  />
                </div>
                <button
                  type="button"
                  phx-click="remove_website"
                  phx-value-index={i}
                  class="btn btn-ghost btn-xs text-error"
                >
                  <.icon name="hero-x-mark-micro" class="size-4" />
                </button>
              </div>
            </div>

            <div class="mt-6">
              <button type="submit" class="btn btn-primary">Save Changes</button>
            </div>
          </.form>

          <form
            phx-change="select_website_type"
            phx-submit="add_website"
            class="flex items-center gap-2 mt-2"
          >
            <select name="type" class="select select-bordered select-sm">
              <option
                :for={{label, value} <- available_website_types(@website_types, @websites)}
                value={value}
                selected={value == @add_website_type}
              >
                {label}
              </option>
            </select>
            <button type="submit" class="btn btn-ghost btn-sm">
              <.icon name="hero-plus-micro" class="size-4" /> Add Website
            </button>
          </form>

          <div class="card bg-base-200 border border-base-300 p-4 space-y-3">
            <h2 class="text-sm font-semibold opacity-70">Career Goal</h2>
            <p :if={@career_goal} class="text-sm">{@career_goal}</p>
            <p :if={!@career_goal} class="text-sm opacity-50">No career goal set yet.</p>

            <.form
              for={@career_goal_form}
              phx-submit="update_career_goal"
              class="space-y-2"
            >
              <.input
                field={@career_goal_form[:instruction]}
                placeholder="e.g. I'm now targeting DevOps roles"
                label=""
              />
              <div class="flex justify-end">
                <button
                  type="submit"
                  class="btn btn-primary btn-sm"
                  disabled={@processing_career_goal}
                >
                  <span :if={@processing_career_goal} class="loading loading-spinner loading-xs">
                  </span>
                  <.icon :if={!@processing_career_goal} name="hero-sparkles-micro" class="size-4" />
                  Update
                </button>
              </div>
            </.form>
          </div>
        </div>

        <%!-- Details & Rules Tab --%>
        <div :if={@active_tab == :details_rules} class="space-y-6">
          <p class="text-sm opacity-70">
            <strong>Details</strong>
            are facts about your career — jobs, skills, education, projects — that
            we use to generate your resumes. <strong>Rules</strong>
            are instructions that shape how resumes are written, like "emphasize
            leadership" or "keep it to one page."
          </p>

          <div id="coach-banner" class="alert bg-primary/10 border-primary/20">
            <.icon name="hero-chat-bubble-left-right" class="size-5 text-primary" />
            <div>
              <p class="font-medium text-sm">
                Want to update your profile through a guided conversation?
              </p>
              <p class="text-xs opacity-70">
                The Career Coach will ask what's changed and update your details.
              </p>
            </div>
            <.link navigate={~p"/coach"} class="btn btn-sm btn-primary">Start Session</.link>
          </div>

          <%!-- Toolbar --%>
          <div class="flex items-center justify-between gap-2">
            <form
              :if={length(@facts) + length(@directives) > 0}
              phx-change="filter_items"
              phx-submit="filter_items"
              class="flex items-center gap-2"
            >
              <input
                type="text"
                placeholder="Filter items..."
                value={@filter}
                phx-debounce="200"
                name="filter"
                class="input input-bordered input-sm w-full max-w-xs"
              />
              <button
                :if={@filter != ""}
                type="button"
                phx-click="clear_filter"
                class="btn btn-ghost btn-xs"
              >
                <.icon name="hero-x-mark-micro" class="size-4" /> Clear
              </button>
            </form>
            <div :if={length(@facts) + length(@directives) == 0} />
            <button phx-click="add_detail" class="btn btn-ghost btn-sm ml-auto">
              <.icon name="hero-plus-micro" class="size-4" /> Add Detail
            </button>
          </div>

          <%!-- Card Grid --%>
          <div
            :if={combined_items(@facts, @directives, @filter) != []}
            id="facts-grid"
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3"
          >
            <div
              :for={item <- combined_items(@facts, @directives, @filter)}
              class="card bg-base-200 border border-base-300 p-3 flex flex-col gap-2"
            >
              <div class="flex items-center justify-between">
                <span class={[
                  "badge badge-sm",
                  if(item.type == :fact, do: "badge-info", else: "badge-warning")
                ]}>
                  {if item.type == :fact, do: "Detail", else: "Rule"}
                </span>
                <button
                  type="button"
                  phx-click="delete_item"
                  phx-value-type={item.type}
                  phx-value-index={item.index}
                  class="btn btn-ghost btn-xs"
                  aria-label={"Delete #{item.type}"}
                >
                  <.icon name="hero-x-mark" class="size-4" />
                </button>
              </div>
              <%!-- View mode --%>
              <p
                :if={@editing_item != {item.type, item.index}}
                class="text-sm cursor-pointer hover:bg-base-300/50 rounded px-1 -mx-1 transition-colors"
                phx-click="edit_item"
                phx-value-type={item.type}
                phx-value-index={item.index}
              >
                {item.text}
              </p>

              <%!-- Edit mode --%>
              <.form
                :if={@editing_item == {item.type, item.index}}
                for={@item_form}
                phx-submit="save_item"
                class="flex flex-col gap-2"
              >
                <textarea
                  name="item[text]"
                  rows="3"
                  class="textarea textarea-bordered textarea-sm w-full"
                  phx-key="Escape"
                  phx-keydown="cancel_edit_item"
                  autofocus
                >{@item_form[:text].value}</textarea>
                <div class="flex gap-1 justify-end">
                  <button type="submit" class="btn btn-primary btn-xs">Save</button>
                  <button type="button" phx-click="cancel_edit_item" class="btn btn-ghost btn-xs">
                    Cancel
                  </button>
                </div>
              </.form>
            </div>
          </div>

          <div
            :if={@facts == [] && @directives == []}
            class="text-sm opacity-50 text-center py-8"
          >
            No details or rules yet. Add a detail manually, or start a Career Coach session
            to build your profile through conversation.
          </div>

          <div
            :if={
              (@facts != [] || @directives != []) &&
                combined_items(@facts, @directives, @filter) == [] && @filter != ""
            }
            class="text-sm opacity-50 text-center py-4"
          >
            No items match your filter.
          </div>
        </div>
      </div>

      <.tutorial
        id="profile-tutorial"
        show={@show_tutorial}
        steps={[
          %{
            target: "#coach-banner",
            message: "Start a Career Coach session to add details through a guided conversation.",
            position: "bottom"
          },
          %{
            target: "#facts-grid",
            message:
              "These are the details and rules we know about you. You can edit or delete anything.",
            position: "top"
          }
        ]}
      />
    </Layouts.app>
    """
  end

  defp combined_items(facts, directives, filter) do
    fact_items =
      facts
      |> Enum.with_index()
      |> Enum.map(fn {text, idx} -> %{type: :fact, text: text, index: idx} end)

    directive_items =
      directives
      |> Enum.with_index()
      |> Enum.map(fn {text, idx} -> %{type: :directive, text: text, index: idx} end)

    (fact_items ++ directive_items)
    |> Enum.filter(fn item ->
      filter == "" || String.contains?(String.downcase(item.text), String.downcase(filter))
    end)
  end

  # Tutorial

  @impl true
  def handle_event("dismiss_tutorial", %{"id" => id}, socket) do
    Accounts.dismiss_tutorial(socket.assigns.user, id)
    {:noreply, assign(socket, show_tutorial: false)}
  end

  # Tab switching

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, active_tab: tab)}
  end

  # Filter

  @impl true
  def handle_event("filter_items", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, filter: filter)}
  end

  @impl true
  def handle_event("clear_filter", _params, socket) do
    {:noreply, assign(socket, filter: "")}
  end

  # Inline editing

  @impl true
  def handle_event("edit_item", %{"type" => type, "index" => index}, socket) do
    type_atom = String.to_existing_atom(type)
    idx = String.to_integer(index)
    list = if type_atom == :fact, do: socket.assigns.facts, else: socket.assigns.directives
    current_text = Enum.at(list, idx, "")

    {:noreply,
     assign(socket,
       editing_item: {type_atom, idx},
       item_form: to_form(%{"text" => current_text}, as: "item")
     )}
  end

  @impl true
  def handle_event("save_item", %{"item" => %{"text" => text}}, socket) do
    {type, index} = socket.assigns.editing_item
    text = String.trim(text)

    {list_key, update_fn} =
      if type == :fact,
        do: {:facts, &Accounts.update_user_facts/2},
        else: {:directives, &Accounts.update_user_directives/2}

    if text == "" do
      # Remove empty items (e.g. cancelled new detail)
      updated_list = List.delete_at(socket.assigns[list_key], index)
      {:ok, user} = update_fn.(socket.assigns.user, updated_list)

      {:noreply,
       assign(socket, [{list_key, Map.get(user, list_key)}, user: user, editing_item: nil])}
    else
      updated_list = List.replace_at(socket.assigns[list_key], index, text)
      {:ok, user} = update_fn.(socket.assigns.user, updated_list)

      {:noreply,
       assign(socket, [{list_key, Map.get(user, list_key)}, user: user, editing_item: nil])}
    end
  end

  @impl true
  def handle_event("cancel_edit_item", _params, socket) do
    # Remove empty placeholder facts (from "Add Detail" that was cancelled)
    facts = Enum.reject(socket.assigns.facts, &(&1 == ""))
    {:noreply, assign(socket, editing_item: nil, facts: facts)}
  end

  # Add detail

  @impl true
  def handle_event("add_detail", _params, socket) do
    facts = socket.assigns.facts ++ [""]
    new_index = length(facts) - 1

    {:noreply,
     assign(socket,
       facts: facts,
       editing_item: {:fact, new_index},
       item_form: to_form(%{"text" => ""}, as: "item")
     )}
  end

  # Delete unified

  @impl true
  def handle_event("delete_item", %{"type" => "fact", "index" => index}, socket) do
    index = String.to_integer(index)
    facts = List.delete_at(socket.assigns.facts, index)
    {:ok, user} = Accounts.update_user_facts(socket.assigns.user, facts)
    {:noreply, assign(socket, facts: user.facts, user: user)}
  end

  @impl true
  def handle_event("delete_item", %{"type" => "directive", "index" => index}, socket) do
    index = String.to_integer(index)
    directives = List.delete_at(socket.assigns.directives, index)
    {:ok, user} = Accounts.update_user_directives(socket.assigns.user, directives)
    {:noreply, assign(socket, directives: user.directives, user: user)}
  end

  # Career goal

  @impl true
  def handle_event(
        "update_career_goal",
        %{"career_goal" => %{"instruction" => instruction}},
        socket
      ) do
    instruction = String.trim(instruction)

    if instruction == "" do
      {:noreply, socket}
    else
      user = socket.assigns.user
      profile = user.default_resume_data

      task =
        Task.async(fn ->
          Resume.Interview.regenerate_career_goal(
            instruction,
            socket.assigns.career_goal,
            socket.assigns.facts,
            profile,
            user_id: user.id
          )
        end)

      {:noreply,
       socket
       |> assign(
         processing_career_goal: true,
         career_goal_form: to_form(%{"instruction" => ""}, as: "career_goal")
       )
       |> update(:task_refs, &Map.put(&1, task.ref, :career_goal))}
    end
  end

  # Profile form

  @impl true
  def handle_event("validate", %{"profile" => params}, socket) do
    {:noreply,
     assign(socket,
       profile_form: to_form(params, as: "profile"),
       websites: all_websites_from_params(params)
     )}
  end

  @impl true
  def handle_event("save", %{"profile" => params}, socket) do
    user = socket.assigns.user
    websites = websites_from_params(params)
    params = Map.put(params, "websites", websites)

    case Accounts.update_user_profile(user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(
           websites: websites,
           profile_form: to_form(params, as: "profile")
         )
         |> put_flash(:info, "Profile updated successfully.")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(profile_form: to_form(params, as: "profile"))
         |> put_flash(:error, "Please fill in your name.")}
    end
  end

  @impl true
  def handle_event("select_website_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, add_website_type: type)}
  end

  @impl true
  def handle_event("add_website", %{"type" => type}, socket) do
    websites = socket.assigns.websites ++ [%{"type" => type, "url" => default_url(type)}]
    available = available_website_types(@website_types, websites)
    default_type = if available == [], do: "custom", else: elem(hd(available), 1)
    {:noreply, assign(socket, websites: websites, add_website_type: default_type)}
  end

  @impl true
  def handle_event("add_website", _params, socket) do
    type = socket.assigns.add_website_type
    websites = socket.assigns.websites ++ [%{"type" => type, "url" => default_url(type)}]
    available = available_website_types(@website_types, websites)
    default_type = if available == [], do: "custom", else: elem(hd(available), 1)
    {:noreply, assign(socket, websites: websites, add_website_type: default_type)}
  end

  @impl true
  def handle_event("remove_website", %{"index" => index}, socket) do
    index = String.to_integer(index)
    websites = List.delete_at(socket.assigns.websites, index)
    {:noreply, assign(socket, websites: websites)}
  end

  # Task results

  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:career_goal, {:ok, new_goal}} ->
        user = socket.assigns.user

        case Accounts.update_user_career_goal(user, new_goal) do
          {:ok, user} ->
            {:noreply,
             socket
             |> assign(
               processing_career_goal: false,
               career_goal: new_goal,
               career_goal_form: to_form(%{"instruction" => ""}, as: "career_goal"),
               user: user
             )
             |> put_flash(:info, "Career goal updated.")}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(processing_career_goal: false)
             |> put_flash(:error, "Failed to save career goal. Please try again.")}
        end

      {:career_goal, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(processing_career_goal: false)
         |> put_flash(:error, "Failed to update career goal. Please try again.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  defp all_websites_from_params(%{"websites" => websites}) when is_map(websites) do
    websites
    |> Enum.sort_by(fn {k, _v} -> String.to_integer(k) end)
    |> Enum.map(fn {_k, v} -> v end)
  end

  defp all_websites_from_params(_), do: []

  defp websites_from_params(%{"websites" => websites}) when is_map(websites) do
    websites
    |> Enum.sort_by(fn {k, _v} -> String.to_integer(k) end)
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.reject(fn w -> (w["url"] || "") |> String.trim() == "" end)
  end

  defp websites_from_params(_), do: []

  defp available_website_types(types, websites) do
    used = MapSet.new(websites, fn w -> w["type"] end)
    Enum.reject(types, fn {_label, value} -> value != "custom" && MapSet.member?(used, value) end)
  end

  defp default_url("linkedin"), do: "https://www.linkedin.com/in/"
  defp default_url("github"), do: "https://github.com/"
  defp default_url(_), do: ""

  defp website_type_label("linkedin"), do: "LinkedIn"
  defp website_type_label("github"), do: "GitHub"
  defp website_type_label("custom"), do: "Custom"
  defp website_type_label(_), do: "Custom"
end
