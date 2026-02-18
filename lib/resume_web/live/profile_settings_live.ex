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

    {:ok,
     assign(socket,
       user: user,
       career_goal: career_goal,
       websites: websites,
       website_types: @website_types,
       add_website_type: "linkedin",
       profile_form: to_form(profile_data, as: "profile"),
       facts: user.facts || [],
       directives: user.directives || [],
       active_tab: :profile,
       input_form: to_form(%{"text" => ""}, as: "input"),
       filter: "",
       processing: false,
       recording: false,
       transcribing: false,
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
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="text-sm breadcrumbs p-0">
          <ul>
            <li><.link navigate={~p"/home"}>Home</.link></li>
            <li>Profile</li>
          </ul>
        </div>
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

          <div :if={@career_goal} class="card bg-base-200 border border-base-300 p-4">
            <h2 class="text-sm font-semibold opacity-70 mb-1">Career Goal</h2>
            <p class="text-sm">{@career_goal}</p>
            <p class="text-xs opacity-50 mt-2">
              Extracted from your interview. Re-do the interview to update.
            </p>
          </div>
        </div>

        <%!-- Details & Rules Tab --%>
        <div :if={@active_tab == :details_rules} class="space-y-6">
          <%!-- Agentic Input --%>
          <div class="space-y-3">
            <.form
              for={@input_form}
              phx-change="validate_input"
              phx-submit="process_input"
              class="rounded-lg border border-base-300 focus-within:border-primary transition-colors"
            >
              <textarea
                id={@input_form[:text].id}
                name={@input_form[:text].name}
                placeholder="Add details or rules — just type naturally, e.g. 'I worked at Google for 3 years as a senior engineer' or 'always emphasize leadership skills'"
                autocomplete="off"
                rows="2"
                phx-hook="AutoGrow"
                class="w-full resize-none overflow-hidden border-none bg-transparent px-3 pt-3 pb-1 text-sm focus:outline-none focus:ring-0"
              >{Phoenix.HTML.Form.normalize_value("textarea", @input_form[:text].value)}</textarea>
              <div class="flex items-center justify-end gap-1 px-2 pb-2">
                <%= if @recording do %>
                  <button
                    type="button"
                    phx-click="stop_recording"
                    class="btn btn-error btn-xs btn-circle"
                  >
                    <.icon name="hero-stop-solid" class="size-3.5" />
                  </button>
                <% else %>
                  <button
                    type="button"
                    phx-click="start_recording"
                    class="btn btn-ghost btn-xs btn-circle"
                  >
                    <.icon name="hero-microphone-solid" class="size-3.5" />
                  </button>
                <% end %>
                <button
                  type="submit"
                  class="btn btn-primary btn-xs btn-circle"
                  disabled={@processing || @transcribing}
                >
                  <.icon name="hero-sparkles-micro" class="size-3.5" />
                </button>
              </div>
            </.form>

            <div
              id="audio-recorder"
              phx-hook=".AudioRecorder"
              phx-update="ignore"
              data-recording={to_string(@recording)}
            >
            </div>

            <div :if={@transcribing} class="flex items-center gap-2 text-sm">
              <span class="loading loading-spinner loading-xs"></span> Transcribing audio...
            </div>

            <div :if={@processing} class="flex items-center gap-2 text-sm">
              <span class="loading loading-spinner loading-xs"></span> Processing input...
            </div>
          </div>

          <%!-- Filter --%>
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

          <%!-- Card Grid --%>
          <div
            :if={combined_items(@facts, @directives, @filter) != []}
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
              <p class="text-sm">{item.text}</p>
            </div>
          </div>

          <div
            :if={@facts == [] && @directives == []}
            class="text-sm opacity-50 text-center py-8"
          >
            No details or rules yet. Use the input above to add some — just describe your
            experience or instructions naturally.
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
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AudioRecorder">
      export default {
        mounted() {
          this.mediaRecorder = null;
          this.audioChunks = [];

          this.handleEvent("start_recording", () => this.startRecording());
          this.handleEvent("stop_recording", () => this.stopRecording());
        },

        async startRecording() {
          try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            this.audioChunks = [];
            this.mediaRecorder = new MediaRecorder(stream);

            this.mediaRecorder.ondataavailable = (event) => {
              if (event.data.size > 0) {
                this.audioChunks.push(event.data);
              }
            };

            this.mediaRecorder.onstop = () => {
              const blob = new Blob(this.audioChunks, { type: this.mediaRecorder.mimeType });
              const reader = new FileReader();
              reader.onloadend = () => {
                const base64 = reader.result.split(",")[1];
                this.pushEvent("audio_data", {
                  data: base64,
                  size: blob.size,
                  type: blob.type,
                });
              };
              reader.readAsDataURL(blob);

              stream.getTracks().forEach((track) => track.stop());
            };

            this.mediaRecorder.start();
          } catch (error) {
            console.error("Recording error:", error);
            this.pushEvent("recording_error", { reason: error.message });
          }
        },

        stopRecording() {
          if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
            this.mediaRecorder.stop();
          }
        },
      };
    </script>
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

  # Agentic input

  @impl true
  def handle_event("validate_input", %{"input" => params}, socket) do
    {:noreply, assign(socket, input_form: to_form(params, as: "input"))}
  end

  @impl true
  def handle_event("process_input", %{"input" => %{"text" => text}}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      task =
        Task.async(fn ->
          Resume.Facts.process_input(
            text,
            socket.assigns.facts,
            socket.assigns.directives,
            user_id: socket.assigns.user.id
          )
        end)

      {:noreply,
       socket
       |> assign(processing: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :process_input))}
    end
  end

  # Audio recording

  @impl true
  def handle_event("start_recording", _params, socket) do
    socket =
      socket
      |> assign(:recording, true)
      |> push_event("start_recording", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("stop_recording", _params, socket) do
    socket =
      socket
      |> assign(:recording, false)
      |> push_event("stop_recording", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("audio_data", %{"data" => data, "type" => type}, socket) do
    audio_binary = Base.decode64!(data)

    task =
      Task.async(fn ->
        Resume.Transcription.transcribe(audio_binary, content_type: type)
      end)

    {:noreply,
     socket
     |> assign(transcribing: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :transcribe_input))}
  end

  @impl true
  def handle_event("recording_error", %{"reason" => reason}, socket) do
    {:noreply,
     socket
     |> assign(recording: false)
     |> put_flash(:error, "Recording failed: #{reason}")}
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
      {:process_input, {:ok, %{fact_operations: fact_ops, directive_operations: dir_ops}}} ->
        user = socket.assigns.user
        facts = socket.assigns.facts
        directives = socket.assigns.directives

        {updated_facts, fact_descs} = Resume.Facts.apply_changes(facts, fact_ops)
        {updated_directives, dir_descs} = Resume.Facts.apply_changes(directives, dir_ops)

        all_descs = fact_descs ++ dir_descs

        socket =
          socket
          |> assign(processing: false, input_form: to_form(%{"text" => ""}, as: "input"))

        socket =
          if all_descs == [] do
            put_flash(socket, :info, "No changes detected from your input.")
          else
            {:ok, user} = Accounts.update_user_facts(user, updated_facts)
            {:ok, user} = Accounts.update_user_directives(user, updated_directives)

            socket
            |> assign(facts: user.facts, directives: user.directives, user: user)
            |> put_flash(:info, Enum.join(all_descs, "; "))
          end

        {:noreply, socket}

      {:process_input, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(processing: false)
         |> put_flash(:error, "Failed to process input. Please try again.")}

      {:transcribe_input, {:ok, transcript}} ->
        current = socket.assigns.input_form.params["text"] || ""
        new_text = if current == "", do: transcript, else: current <> "\n" <> transcript

        {:noreply,
         socket
         |> assign(
           transcribing: false,
           input_form: to_form(%{"text" => new_text}, as: "input")
         )}

      {:transcribe_input, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> put_flash(:error, "Transcription failed. Please try again.")}

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
