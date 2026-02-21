defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, Feedback, Resumes, Retry}
  alias ResumeWeb.ResumeTemplates.Default

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive,
    "elegant" => ResumeWeb.ResumeTemplates.Elegant,
    "classic" => ResumeWeb.ResumeTemplates.Classic,
    "flat" => ResumeWeb.ResumeTemplates.Flat,
    "kendall" => ResumeWeb.ResumeTemplates.Kendall,
    "editorial" => ResumeWeb.ResumeTemplates.Editorial,
    "typewriter" => ResumeWeb.ResumeTemplates.Typewriter,
    "nordic" => ResumeWeb.ResumeTemplates.Nordic,
    "berlin" => ResumeWeb.ResumeTemplates.Berlin,
    "even" => ResumeWeb.ResumeTemplates.Even,
    "paper" => ResumeWeb.ResumeTemplates.Paper,
    "consultant" => ResumeWeb.ResumeTemplates.Consultant,
    "sidebar" => ResumeWeb.ResumeTemplates.Sidebar,
    "stackoverflow" => ResumeWeb.ResumeTemplates.Stackoverflow,
    "academic" => ResumeWeb.ResumeTemplates.Academic,
    "minimalist" => ResumeWeb.ResumeTemplates.Minimalist,
    "macchiato" => ResumeWeb.ResumeTemplates.Macchiato
  }

  @generating_messages [
    "Reviewing your career history...",
    "Rephrasing your accomplishments...",
    "Highlighting your specific skills...",
    "Crafting your professional summary...",
    "Tailoring details to the job description...",
    "Polishing the final details..."
  ]

  @feedback_placeholders [
    "Can you emphasize my leadership experience more in the summary?",
    "Make the summary focus more on my technical skills",
    "Add more detail about my project management experience",
    "Tone down the soft skills and highlight the engineering work",
    "Can you make the summary sound more senior-level?",
    "Rewrite the summary to better target a product management role",
    "Emphasize my experience with distributed systems throughout",
    "Can you highlight my mentoring and team-building contributions?",
    "Make the work experience bullet points more results-oriented",
    "Focus more on my cloud infrastructure and DevOps experience"
  ]

  @template_options [
    {"Default", "default"},
    {"Mono", "mono"},
    {"Fresh", "fresh"},
    {"Executive", "executive"},
    {"Elegant", "elegant"},
    {"Classic", "classic"},
    {"Flat", "flat"},
    {"Kendall", "kendall"},
    {"Editorial", "editorial"},
    {"Typewriter", "typewriter"},
    {"Nordic", "nordic"},
    {"Berlin", "berlin"},
    {"Even", "even"},
    {"Paper", "paper"},
    {"Consultant", "consultant"},
    {"Sidebar", "sidebar"},
    {"Stack Overflow", "stackoverflow"},
    {"Academic", "academic"},
    {"Minimalist", "minimalist"},
    {"Macchiato", "macchiato"}
  ]

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)
    versions = Resumes.list_versions(resume.id)
    current_version = List.first(versions)
    generating = versions == []
    template_mod = Map.get(@templates, resume.template, Default)
    current_data = version_data(current_version)

    socket =
      assign(socket,
        user: user,
        resume: resume,
        versions: versions,
        current_version: current_version,
        template_mod: template_mod,
        template_css: template_mod.css(),
        template_options: @template_options,
        template_previews: build_template_previews(current_data),
        feedback_form: to_form(%{"message" => ""}, as: "feedback"),
        preview_data: nil,
        preview_explanation: nil,
        pending_directive: nil,
        pending_fact_changes: [],
        processing_feedback: false,
        recording: false,
        transcribing: false,
        editing_title: false,
        title_form: to_form(%{"title" => resume.title}, as: "title"),
        editing_section: nil,
        section_form: nil,
        sidebar_open: false,
        show_tutorial: Accounts.show_tutorial?(user, "show-tutorial"),
        upgrade_prompt: nil,
        feedback_placeholder: Enum.random(@feedback_placeholders),
        generating: generating,
        generating_messages: @generating_messages,
        generating_message_index: 0,
        task_refs: %{}
      )

    socket =
      if generating and connected?(socket) do
        task =
          Task.async(fn ->
            Retry.with_retry(fn -> Resumes.generate_initial_version(resume, user) end)
          end)

        Process.send_after(self(), :rotate_generating_message, 3_000)

        update(socket, :task_refs, &Map.put(&1, task.ref, :generate))
      else
        socket
      end

    {:ok, socket}
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

  defp version_data(current_version) do
    if current_version, do: Resumes.dump_version_data(current_version), else: nil
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :current_data, version_data(assigns.current_version))

    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: @resume.title}]}>
      <div class="drawer drawer-end">
        <input
          id="sidebar-toggle"
          type="checkbox"
          class="drawer-toggle"
          checked={@sidebar_open}
          phx-click="toggle_sidebar"
        />
        <div class="drawer-content space-y-6">
          <div :if={@upgrade_prompt} class="alert alert-warning mb-4">
            <.icon name="hero-lock-closed-micro" class="size-5" />
            <span>{@upgrade_prompt}</span>
            <.link navigate={~p"/billing"} class="btn btn-sm btn-primary">
              Get Unlimited Access
            </.link>
          </div>
          <label
            :if={!@generating}
            for="sidebar-toggle"
            class="fixed right-0 top-1/2 -translate-y-1/2 z-10 bg-base-200 hover:bg-base-300 transition-colors rounded-l-lg px-2.5 py-5 cursor-pointer shadow-md"
          >
            <.icon name="hero-chevron-left-micro" class="size-5" />
          </label>

          <div class="space-y-1">
            <div class="flex items-center justify-between">
              <div :if={!@editing_title} class="flex items-center gap-2 group">
                <h1 class="text-2xl font-bold">{@resume.title}</h1>
                <button
                  phx-click="edit_title"
                  class="opacity-0 group-hover:opacity-60 hover:!opacity-100 transition-opacity"
                >
                  <.icon name="hero-pencil-square-micro" class="size-4" />
                </button>
              </div>
              <.form
                :if={@editing_title}
                for={@title_form}
                phx-submit="save_title"
                class="flex items-center gap-2"
              >
                <input
                  type="text"
                  name="title[title]"
                  value={@title_form[:title].value}
                  class="input input-sm w-full max-w-md"
                  autofocus
                  phx-key="Escape"
                  phx-keydown="cancel_edit_title"
                />
                <button type="submit" class="btn btn-primary btn-sm">Save</button>
                <button type="button" phx-click="cancel_edit_title" class="btn btn-ghost btn-sm">
                  Cancel
                </button>
              </.form>
              <div class="flex items-center gap-2">
                <.link
                  :if={@current_version}
                  href={~p"/resumes/#{@resume}/pdf"}
                  class="btn btn-sm"
                >
                  <.icon name="hero-arrow-down-tray-micro" class="size-4" /> Download PDF
                </.link>
                <button
                  phx-click="delete"
                  data-confirm="Are you sure you want to delete this resume?"
                  class="btn btn-ghost btn-sm text-error"
                >
                  Delete
                </button>
              </div>
            </div>

            <div class="flex items-center gap-3 text-sm text-base-content/60">
              <span
                :if={@resume.job_posting_text || @resume.job_posting_url}
                class="badge badge-accent badge-sm cursor-default"
              >
                Targeted
              </span>
              <span>Created {Calendar.strftime(@resume.inserted_at, "%b %d, %Y")}</span>
              <.link navigate={~p"/profile?tab=details_rules"} class="link link-hover">
                Edit Profile Details
              </.link>
            </div>
          </div>

          <div :if={@generating} class="flex flex-col items-center justify-center py-32 gap-6">
            <span class="loading loading-spinner loading-lg text-primary"></span>
            <p class="text-lg text-base-content/60 animate-pulse">
              {Enum.at(@generating_messages, @generating_message_index)}
            </p>
          </div>

          <div :if={!@generating && @current_data} class="space-y-4">
            <div
              id="audio-recorder"
              phx-hook="AudioRecorder"
              phx-update="ignore"
              data-recording={to_string(@recording)}
            >
            </div>

            <div
              :if={@processing_feedback}
              class="flex items-center gap-2 text-sm text-base-content/70"
            >
              <span class="loading loading-spinner loading-sm"></span> Updating resume...
            </div>

            <div :if={!@processing_feedback && @preview_data} class="space-y-3">
              <div :if={@preview_explanation} class="bg-base-200 rounded-lg p-3 text-sm">
                <p class="font-medium mb-1">What changed</p>
                <p class="text-base-content/70">{@preview_explanation}</p>
              </div>

              <div :if={@pending_directive} class="bg-base-200 rounded-lg p-3 text-sm">
                <p class="mb-2">Should this always apply?</p>
                <p class="text-xs opacity-80 mb-2">"{@pending_directive}"</p>
                <div class="flex gap-2">
                  <button phx-click="always_directive" class="btn btn-xs btn-accent">
                    Always
                  </button>
                  <button phx-click="just_this_resume" class="btn btn-xs btn-ghost">
                    Just this resume
                  </button>
                </div>
              </div>

              <div class="flex items-center gap-2">
                <button phx-click="confirm_changes" class="btn btn-primary btn-sm">
                  <.icon name="hero-check-micro" class="size-4" /> Confirm Changes
                </button>
                <button phx-click="revert_changes" class="btn btn-ghost btn-sm">
                  <.icon name="hero-arrow-uturn-left-micro" class="size-4" /> Revert
                </button>
              </div>
            </div>

            <div :if={!@processing_feedback && !@preview_data}>
              <div :if={@transcribing} class="flex items-center gap-2 text-sm mb-2">
                <span class="loading loading-spinner loading-xs"></span> Transcribing...
              </div>

              <.form
                id="feedback-form"
                for={@feedback_form}
                phx-submit="send_feedback"
                phx-change="validate_feedback"
                class="rounded-lg border border-base-300 focus-within:border-primary transition-colors"
              >
                <div :if={@recording} class="flex items-center justify-center gap-1 h-10 px-3">
                  <div
                    :for={i <- 1..5}
                    class="w-1 bg-error rounded-full animate-waveform"
                    style={"animation-delay: #{i * 0.1}s"}
                  />
                </div>
                <textarea
                  :if={!@recording}
                  id={@feedback_form[:message].id}
                  name={@feedback_form[:message].name}
                  placeholder={@feedback_placeholder}
                  autocomplete="off"
                  rows="1"
                  phx-hook="AutoGrow"
                  class="w-full resize-none overflow-hidden border-none bg-transparent px-3 pt-3 pb-1 text-sm focus:outline-none focus:ring-0"
                >{Phoenix.HTML.Form.normalize_value("textarea", @feedback_form[:message].value)}</textarea>
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
                    disabled={@recording || @transcribing}
                  >
                    <.icon name="hero-paper-airplane-solid" class="size-3.5" />
                  </button>
                </div>
              </.form>
            </div>
          </div>

          <div
            :if={!@generating && @current_data}
            id="resume-scale-wrapper"
            phx-hook=".ResumeScale"
            class="overflow-hidden"
          >
            <div
              id="resume-scale-inner"
              phx-hook=".SectionEditor"
              class={[
                "w-[8.5in] bg-white border border-base-300 rounded-sm print:border-none print:p-0 origin-top-left print:!transform-none",
                if(@resume.template in ~w(executive sidebar),
                  do: "p-0 overflow-hidden",
                  else: "p-[0.85in]"
                )
              ]}
            >
              <div
                :if={@preview_data}
                class="flex items-center gap-2 mb-4 -mt-4 -mx-4 px-4 py-2 bg-warning/10 border-b border-warning/30"
              >
                <.icon name="hero-eye-micro" class="size-4 text-warning" />
                <span class="text-sm font-medium text-warning">Preview — unsaved changes</span>
              </div>
              {raw("<style>" <> @template_css <> section_editor_css() <> "</style>")}
              {raw(render_template(@template_mod, display_data(@preview_data, @current_data)))}
            </div>
          </div>
        </div>

        <div class="drawer-side z-10">
          <label for="sidebar-toggle" class="drawer-overlay" aria-label="Close sidebar"></label>
          <div class="bg-base-200 min-h-full w-80 p-4 space-y-6">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold">Settings</h2>
              <label for="sidebar-toggle" class="btn btn-ghost btn-sm btn-square">
                <.icon name="hero-x-mark-micro" class="size-4" />
              </label>
            </div>

            <div :if={length(@versions) > 1} class="space-y-2">
              <h3 class="text-sm font-medium">Version</h3>
              <div class="flex flex-wrap gap-1">
                <button
                  :for={v <- Enum.reverse(@versions)}
                  phx-click="select_version"
                  phx-value-version={v.version}
                  class={[
                    "btn btn-xs",
                    if(v.version == @current_version.version,
                      do: "btn-primary",
                      else: "btn-ghost"
                    )
                  ]}
                >
                  v{v.version}
                  <span class="text-xs opacity-60">{v.trigger}</span>
                </button>
              </div>
            </div>

            <div :if={@resume.job_posting_text || @resume.job_posting_url} class="space-y-2">
              <h3 class="text-sm font-medium">Job Targeting</h3>
              <div
                :if={@resume.job_posting_text}
                class="text-sm bg-base-100 rounded-lg p-3 max-h-40 overflow-y-auto"
              >
                {@resume.job_posting_text}
              </div>
              <.link
                :if={@resume.job_posting_url}
                href={@resume.job_posting_url}
                target="_blank"
                class="link link-primary text-sm"
              >
                {URI.parse(@resume.job_posting_url).host || @resume.job_posting_url}
                <.icon name="hero-arrow-top-right-on-square-micro" class="size-3 inline" />
              </.link>
            </div>

            <div :if={@current_version && @current_version.explanation} class="space-y-2">
              <h3 class="text-sm font-medium">Notes</h3>
              <p class="text-sm bg-base-100 rounded-lg p-3">{@current_version.explanation}</p>
            </div>

            <div class="space-y-2">
              <h3 class="text-sm font-medium">Template</h3>
              <div class="grid grid-cols-2 gap-3">
                <button
                  :for={{name, key} <- @template_options}
                  phx-click="change_template"
                  phx-value-template={key}
                  class={[
                    "rounded-lg overflow-hidden border-2 transition-colors cursor-pointer",
                    if(key == @resume.template,
                      do: "border-primary",
                      else: "border-base-300 hover:border-base-content/30"
                    )
                  ]}
                >
                  <div class="relative w-full aspect-[8.5/11] overflow-hidden">
                    <iframe
                      srcdoc={@template_previews[key]}
                      class="absolute top-0 left-0 w-[8.5in] h-[11in] origin-top-left pointer-events-none"
                      style="transform: scale(calc(1/6));"
                      scrolling="no"
                      tabindex="-1"
                    />
                  </div>
                  <div class="text-xs text-center py-1.5 bg-base-100">{name}</div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <dialog
        :if={@editing_section}
        id="section-editor-modal"
        class="modal modal-open"
        phx-window-keydown="close_section_editor"
        phx-key="Escape"
      >
        <div class="modal-box">
          <h3 class="text-lg font-bold mb-4">Edit {section_label(@editing_section)}</h3>
          <.form for={@section_form} phx-submit="save_section_edit" autocomplete="off">
            <.section_editor_fields
              section={elem(@editing_section, 0)}
              form={@section_form}
            />
            <div class="modal-action">
              <button type="button" phx-click="close_section_editor" class="btn">Cancel</button>
              <button type="submit" class="btn btn-primary">Save</button>
            </div>
          </.form>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button type="button" phx-click="close_section_editor">close</button>
        </form>
      </dialog>

      <.tutorial
        id="show-tutorial"
        show={@show_tutorial}
        steps={[
          %{
            target: "#feedback-form",
            message:
              "Suggest changes using natural language — like 'make the summary shorter' or 'emphasize my Python experience'.",
            position: "bottom"
          },
          %{
            target: "label[for='sidebar-toggle']",
            message: "Open this panel to change the resume template or browse version history.",
            position: "bottom"
          },
          %{
            target: "a[href$='/pdf']",
            message: "Download your resume as a PDF when you're ready.",
            position: "bottom"
          }
        ]}
      />
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ResumeScale">
      export default {
        mounted() {
          this.inner = this.el.querySelector("#resume-scale-inner");
          this.observer = new ResizeObserver(() => this.rescale());
          this.observer.observe(this.el);
          this.rescale();
        },
        updated() {
          this.rescale();
        },
        rescale() {
          const inner = this.inner;
          if (!inner) return;
          inner.style.transform = "";
          this.el.style.height = "";
          const available = this.el.clientWidth;
          const needed = inner.scrollWidth;
          if (needed > available) {
            const scale = available / needed;
            inner.style.transform = `scale(${scale})`;
            this.el.style.height = `${inner.offsetHeight * scale}px`;
          }
        },
        destroyed() {
          this.observer?.disconnect();
        },
      };
    </script>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".SectionEditor">
      export default {
        mounted() {
          this.el.addEventListener("click", (e) => {
            const target = e.target.closest("[data-section]");
            if (!target) return;
            e.preventDefault();
            this.pushEvent("open_section_editor", {
              section: target.dataset.section,
              index: target.dataset.sectionIndex ?? null,
            });
          });

          this.el.addEventListener("mouseover", (e) => {
            const target = e.target.closest("[data-section]");
            if (this._hovered && this._hovered !== target) {
              this._hovered.classList.remove("section-editable-hover");
            }
            if (target) {
              target.classList.add("section-editable-hover");
              this._hovered = target;
            }
          });

          this.el.addEventListener("mouseout", (e) => {
            if (this._hovered) {
              this._hovered.classList.remove("section-editable-hover");
              this._hovered = null;
            }
          });
        },
      };
    </script>
    """
  end

  @impl true
  def handle_event("dismiss_tutorial", %{"id" => id}, socket) do
    Accounts.dismiss_tutorial(socket.assigns.user, id)
    {:noreply, assign(socket, show_tutorial: false)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("select_version", %{"version" => version_str}, socket) do
    version_number = String.to_integer(version_str)
    current_version = Resumes.get_version!(socket.assigns.resume.id, version_number)

    {:noreply,
     assign(socket,
       current_version: current_version,
       template_previews: build_template_previews(version_data(current_version)),
       preview_data: nil,
       preview_explanation: nil,
       pending_directive: nil
     )}
  end

  @impl true
  def handle_event("edit_title", _params, socket) do
    {:noreply, assign(socket, editing_title: true)}
  end

  @impl true
  def handle_event("cancel_edit_title", _params, socket) do
    {:noreply,
     assign(socket,
       editing_title: false,
       title_form: to_form(%{"title" => socket.assigns.resume.title}, as: "title")
     )}
  end

  @impl true
  def handle_event("save_title", %{"title" => %{"title" => title}}, socket) do
    title = String.trim(title)

    if title == "" do
      {:noreply, put_flash(socket, :error, "Title can't be blank.")}
    else
      case Resumes.update_resume(socket.assigns.resume, %{title: title}) do
        {:ok, resume} ->
          {:noreply,
           assign(socket,
             resume: resume,
             editing_title: false,
             title_form: to_form(%{"title" => resume.title}, as: "title")
           )}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update title.")}
      end
    end
  end

  @impl true
  def handle_event("change_template", %{"template" => template}, socket) do
    {:ok, resume} = Resumes.update_resume(socket.assigns.resume, %{template: template})
    template_mod = Map.get(@templates, template, Default)

    {:noreply,
     assign(socket,
       resume: resume,
       template_mod: template_mod,
       template_css: template_mod.css()
     )}
  end

  # Feedback events

  @impl true
  def handle_event("validate_feedback", %{"feedback" => params}, socket) do
    {:noreply, assign(socket, feedback_form: to_form(params, as: "feedback"))}
  end

  @impl true
  def handle_event("send_feedback", %{"feedback" => %{"message" => message}}, socket) do
    message = String.trim(message)

    if message == "" do
      {:noreply, socket}
    else
      {:noreply, process_feedback_message(socket, message)}
    end
  end

  @impl true
  def handle_event("confirm_changes", _params, socket) do
    preview_data = socket.assigns.preview_data
    explanation = socket.assigns.preview_explanation
    resume = socket.assigns.resume

    case Resumes.confirm_feedback_changes(resume, preview_data, explanation) do
      {:ok, version} ->
        versions = Resumes.list_versions(resume.id)

        socket =
          socket
          |> apply_fact_changes(socket.assigns.pending_fact_changes)
          |> assign(
            versions: versions,
            current_version: version,
            template_previews: build_template_previews(version_data(version)),
            preview_data: nil,
            preview_explanation: nil,
            pending_fact_changes: []
          )
          |> put_flash(:info, "Changes saved.")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save changes.")}
    end
  end

  @impl true
  def handle_event("revert_changes", _params, socket) do
    {:noreply,
     assign(socket,
       preview_data: nil,
       preview_explanation: nil,
       pending_directive: nil,
       pending_fact_changes: []
     )}
  end

  @impl true
  def handle_event("always_directive", _params, socket) do
    directive = socket.assigns.pending_directive
    user = Accounts.get_user!(socket.assigns.user.id)
    directives = (user.directives || []) ++ [directive]

    case Accounts.update_user_directives(user, directives) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(user: user, pending_directive: nil)
         |> put_flash(:info, "Saved as a standing rule.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save directive.")}
    end
  end

  @impl true
  def handle_event("just_this_resume", _params, socket) do
    {:noreply, assign(socket, pending_directive: nil)}
  end

  # Voice recording events

  @impl true
  def handle_event("start_recording", _params, socket) do
    {:noreply,
     socket
     |> assign(:recording, true)
     |> push_event("start_recording", %{})}
  end

  @impl true
  def handle_event("stop_recording", _params, socket) do
    {:noreply,
     socket
     |> assign(:recording, false)
     |> push_event("stop_recording", %{})}
  end

  @impl true
  def handle_event("audio_data", %{"data" => data, "type" => type}, socket) do
    if socket.assigns.processing_feedback do
      {:noreply, assign(socket, recording: false)}
    else
      audio_binary = Base.decode64!(data)
      user_id = socket.assigns.user.id

      task =
        Task.async(fn ->
          Retry.with_retry(fn ->
            Resume.Transcription.tracked_transcribe(audio_binary, [content_type: type], %{
              user_id: user_id,
              caller: "transcription"
            })
          end)
        end)

      {:noreply,
       socket
       |> assign(recording: false, transcribing: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :transcribe_feedback))}
    end
  end

  @impl true
  def handle_event("recording_error", %{"reason" => reason}, socket) do
    {:noreply,
     socket
     |> assign(:recording, false)
     |> put_flash(:error, "Recording failed: #{reason}")}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Resumes.delete_resume(socket.assigns.resume)

    {:noreply,
     socket
     |> put_flash(:info, "Resume deleted.")
     |> push_navigate(to: ~p"/home")}
  end

  # Section editor events

  @impl true
  def handle_event("open_section_editor", %{"section" => section} = params, socket) do
    if socket.assigns.preview_data do
      {:noreply, socket}
    else
      index =
        case params["index"] do
          nil -> nil
          "" -> nil
          idx -> String.to_integer(idx)
        end

      current_data = version_data(socket.assigns.current_version)
      section_form = build_section_form(current_data, section, index)

      {:noreply,
       assign(socket,
         editing_section: {section, index},
         section_form: section_form
       )}
    end
  end

  @impl true
  def handle_event("save_section_edit", %{"section" => params}, socket) do
    {section, index} = socket.assigns.editing_section
    resume = socket.assigns.resume
    data_map = version_data_to_map(socket.assigns.current_version)
    updated_data = apply_section_edit(data_map, section, index, params)
    label = section_label({section, index})

    case Resumes.confirm_direct_edit(resume, updated_data, label) do
      {:ok, version} ->
        versions = Resumes.list_versions(resume.id)

        {:noreply,
         socket
         |> assign(
           versions: versions,
           current_version: version,
           template_previews: build_template_previews(version_data(version)),
           editing_section: nil,
           section_form: nil
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save changes.")}
    end
  end

  @impl true
  def handle_event("close_section_editor", _params, socket) do
    {:noreply, assign(socket, editing_section: nil, section_form: nil)}
  end

  @impl true
  def handle_info(:rotate_generating_message, socket) do
    if socket.assigns.generating do
      next_index =
        rem(socket.assigns.generating_message_index + 1, length(@generating_messages))

      Process.send_after(self(), :rotate_generating_message, 3_000)
      {:noreply, assign(socket, generating_message_index: next_index)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:generate, {:ok, resume}} ->
        resume = Resumes.get_user_resume!(socket.assigns.user.id, resume.id)
        versions = Resumes.list_versions(resume.id)
        current_version = List.first(versions)
        current_data = version_data(current_version)
        template_mod = Map.get(@templates, resume.template, Default)

        {:noreply,
         socket
         |> assign(
           generating: false,
           resume: resume,
           versions: versions,
           current_version: current_version,
           template_mod: template_mod,
           template_css: template_mod.css(),
           template_previews: build_template_previews(current_data),
           title_form: to_form(%{"title" => resume.title}, as: "title")
         )
         |> put_flash(:info, "Your resume is ready!")}

      {:generate, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(generating: false)
         |> put_flash(:error, "Failed to generate resume. Please try again.")}

      {:feedback, {:ok, result}} ->
        {:noreply, handle_feedback_result(socket, result)}

      {:feedback, {:error, :limit_reached, message}} ->
        {:noreply,
         socket
         |> assign(processing_feedback: false, upgrade_prompt: message)}

      {:feedback, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(processing_feedback: false)
         |> put_flash(:error, "Failed to process feedback. Please try again.")}

      {:transcribe_feedback, {:ok, transcript}} when not socket.assigns.processing_feedback ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> process_feedback_message(transcript)}

      {:transcribe_feedback, {:ok, _transcript}} ->
        {:noreply, assign(socket, transcribing: false)}

      {:transcribe_feedback, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> put_flash(:error, "Transcription failed. Please try typing instead.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  defp build_template_previews(nil), do: %{}

  defp build_template_previews(data) do
    Map.new(@templates, fn {key, mod} ->
      html = render_template(mod, data)
      css = mod.css()
      full_bleed? = key in ~w(executive sidebar)
      body_padding = if full_bleed?, do: "0", else: "0.85in"

      srcdoc = """
      <!DOCTYPE html>
      <html lang="en">
      <head>
      <meta charset="UTF-8">
      <style>#{css}
      html { width: 8.5in; }
      body { margin: 0; padding: #{body_padding}; overflow: hidden; }
      </style>
      </head>
      <body>#{html}</body>
      </html>
      """

      {key, srcdoc}
    end)
  end

  defp render_template(template_mod, data) do
    template_mod.render(%{data: data})
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp display_data(nil, current_data), do: current_data

  defp display_data(preview_data, _current_data) do
    %Resume.Resumes.ResumeData{}
    |> Resume.Resumes.ResumeData.changeset(preview_data)
    |> Ecto.Changeset.apply_changes()
  end

  defp process_feedback_message(socket, message) do
    user = Accounts.get_user!(socket.assigns.user.id)
    current_version = socket.assigns.current_version
    current_data = socket.assigns.preview_data || version_data_to_map(current_version)

    task =
      Task.async(fn ->
        Retry.with_retry(fn ->
          Feedback.process_feedback(current_data, user, message, history: [])
        end)
      end)

    socket
    |> assign(
      processing_feedback: true,
      feedback_form: to_form(%{"message" => ""}, as: "feedback"),
      user: user
    )
    |> update(:task_refs, &Map.put(&1, task.ref, :feedback))
  end

  defp handle_feedback_result(socket, result) do
    current_data =
      socket.assigns.preview_data || version_data_to_map(socket.assigns.current_version)

    if result.data == current_data do
      socket
      |> assign(processing_feedback: false)
      |> put_flash(:info, "No changes to apply. Try being more specific about what to change.")
    else
      socket =
        assign(socket,
          processing_feedback: false,
          preview_data: result.data,
          preview_explanation: result.explanation
        )

      # Handle classification
      socket =
        case result.classification do
          :directive when is_binary(result.directive) ->
            user = Accounts.get_user!(socket.assigns.user.id)
            directives = (user.directives || []) ++ [result.directive]

            case Accounts.update_user_directives(user, directives) do
              {:ok, user} -> assign(socket, user: user)
              {:error, _} -> socket
            end

          :ambiguous when is_binary(result.directive) ->
            assign(socket, pending_directive: result.directive)

          _ ->
            socket
        end

      # Stash fact changes for apply on confirm
      assign(socket, pending_fact_changes: result.fact_changes)
    end
  end

  defp apply_fact_changes(socket, []), do: socket

  defp apply_fact_changes(socket, changes) do
    user = Accounts.get_user!(socket.assigns.user.id)
    facts = user.facts || []

    {facts, _descriptions} = Resume.Facts.apply_changes(facts, changes)

    case Accounts.update_user_facts(user, facts) do
      {:ok, user} -> assign(socket, user: user)
      {:error, _} -> socket
    end
  end

  defp version_data_to_map(nil), do: %{}

  defp version_data_to_map(%{data: data}) do
    data
    |> Jason.encode!()
    |> Jason.decode!()
  end

  # Section editor helpers

  defp section_editor_css do
    """
    [data-section] { cursor: pointer; transition: outline 0.15s; border-radius: 2px; }
    [data-section].section-editable-hover { outline: 2px solid oklch(0.65 0.2 250 / 0.5); outline-offset: 4px; }
    """
  end

  defp section_label({"contact_info", _}), do: "Contact Info"
  defp section_label({"summary", _}), do: "Summary"
  defp section_label({"work_experience", _}), do: "Work Experience"
  defp section_label({"education", _}), do: "Education"
  defp section_label({"skills", _}), do: "Skills"
  defp section_label({"certifications", _}), do: "Certifications"
  defp section_label({"projects", _}), do: "Projects"
  defp section_label({"publications", _}), do: "Publications"
  defp section_label({"volunteer_work", _}), do: "Volunteer Work"
  defp section_label({"languages", _}), do: "Languages"
  defp section_label({"awards", _}), do: "Awards"

  # Section editor form fields component

  attr :section, :string, required: true
  attr :form, :any, required: true

  defp section_editor_fields(%{section: "contact_info"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:email]} type="text" label="Email" />
      <.input field={@form[:phone]} type="text" label="Phone" />
      <.input field={@form[:location]} type="text" label="Location" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "summary"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:summary]} type="textarea" label="Summary" rows="5" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "work_experience"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:role]} type="text" label="Role" />
      <.input field={@form[:company]} type="text" label="Company" />
      <.input field={@form[:current]} type="checkbox" label="Current position" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:start_date_year]} type="number" label="Start year" />
        <.input field={@form[:start_date_month]} type="number" label="Start month" />
      </div>
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:end_date_year]} type="number" label="End year" />
        <.input field={@form[:end_date_month]} type="number" label="End month" />
      </div>
      <.input
        field={@form[:accomplishments]}
        type="textarea"
        label="Accomplishments (one per line)"
        rows="5"
      />
    </div>
    """
  end

  defp section_editor_fields(%{section: "education"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:institution]} type="text" label="Institution" />
      <.input field={@form[:degree]} type="text" label="Degree" />
      <.input field={@form[:field]} type="text" label="Field of study" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:start_date_year]} type="number" label="Start year" />
        <.input field={@form[:start_date_month]} type="number" label="Start month" />
      </div>
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:end_date_year]} type="number" label="End year" />
        <.input field={@form[:end_date_month]} type="number" label="End month" />
      </div>
    </div>
    """
  end

  defp section_editor_fields(%{section: "skills"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:category]} type="text" label="Category" />
      <.input field={@form[:skills]} type="textarea" label="Skills (comma-separated)" rows="3" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "certifications"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:issuer]} type="text" label="Issuer" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:date_year]} type="number" label="Year" />
        <.input field={@form[:date_month]} type="number" label="Month" />
      </div>
    </div>
    """
  end

  defp section_editor_fields(%{section: "projects"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:name]} type="text" label="Name" />
      <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
      <.input field={@form[:url]} type="text" label="URL" />
      <.input
        field={@form[:highlights]}
        type="textarea"
        label="Highlights (one per line)"
        rows="4"
      />
    </div>
    """
  end

  defp section_editor_fields(%{section: "publications"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:title]} type="text" label="Title" />
      <.input field={@form[:publisher]} type="text" label="Publisher" />
      <.input field={@form[:url]} type="text" label="URL" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:date_year]} type="number" label="Year" />
        <.input field={@form[:date_month]} type="number" label="Month" />
      </div>
    </div>
    """
  end

  defp section_editor_fields(%{section: "volunteer_work"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:role]} type="text" label="Role" />
      <.input field={@form[:organization]} type="text" label="Organization" />
      <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:start_date_year]} type="number" label="Start year" />
        <.input field={@form[:start_date_month]} type="number" label="Start month" />
      </div>
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:end_date_year]} type="number" label="End year" />
        <.input field={@form[:end_date_month]} type="number" label="End month" />
      </div>
    </div>
    """
  end

  defp section_editor_fields(%{section: "languages"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:name]} type="text" label="Language" />
      <.input field={@form[:fluency]} type="text" label="Fluency" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "awards"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:title]} type="text" label="Title" />
      <.input field={@form[:issuer]} type="text" label="Issuer" />
      <.input field={@form[:summary]} type="textarea" label="Summary" rows="3" />
      <div class="grid grid-cols-2 gap-3">
        <.input field={@form[:date_year]} type="number" label="Year" />
        <.input field={@form[:date_month]} type="number" label="Month" />
      </div>
    </div>
    """
  end

  # Build form for section editing

  defp build_section_form(data, "contact_info", _index) do
    contact = data.contact_info

    to_form(
      %{
        "name" => (contact && contact.name) || "",
        "email" => (contact && contact.email) || "",
        "phone" => (contact && contact.phone) || "",
        "location" => (contact && contact.location) || ""
      },
      as: "section"
    )
  end

  defp build_section_form(data, "summary", _index) do
    to_form(%{"summary" => data.summary || ""}, as: "section")
  end

  defp build_section_form(data, "work_experience", index) do
    exp = Enum.at(data.work_experience || [], index)

    to_form(
      %{
        "role" => (exp && exp.role) || "",
        "company" => (exp && exp.company) || "",
        "current" => to_string((exp && exp.current) || false),
        "start_date_year" => flex_date_field(exp && exp.start_date, :year),
        "start_date_month" => flex_date_field(exp && exp.start_date, :month),
        "end_date_year" => flex_date_field(exp && exp.end_date, :year),
        "end_date_month" => flex_date_field(exp && exp.end_date, :month),
        "accomplishments" => Enum.join((exp && exp.accomplishments) || [], "\n")
      },
      as: "section"
    )
  end

  defp build_section_form(data, "education", index) do
    edu = Enum.at(data.education || [], index)

    to_form(
      %{
        "institution" => (edu && edu.institution) || "",
        "degree" => (edu && edu.degree) || "",
        "field" => (edu && edu.field) || "",
        "start_date_year" => flex_date_field(edu && edu.start_date, :year),
        "start_date_month" => flex_date_field(edu && edu.start_date, :month),
        "end_date_year" => flex_date_field(edu && edu.end_date, :year),
        "end_date_month" => flex_date_field(edu && edu.end_date, :month)
      },
      as: "section"
    )
  end

  defp build_section_form(data, "skills", index) do
    group = Enum.at(data.skills || [], index)

    to_form(
      %{
        "category" => (group && group.category) || "",
        "skills" => Enum.join((group && group.skills) || [], ", ")
      },
      as: "section"
    )
  end

  defp build_section_form(data, "certifications", index) do
    cert = Enum.at(data.certifications || [], index)

    to_form(
      %{
        "name" => (cert && cert.name) || "",
        "issuer" => (cert && cert.issuer) || "",
        "date_year" => flex_date_field(cert && cert.date, :year),
        "date_month" => flex_date_field(cert && cert.date, :month)
      },
      as: "section"
    )
  end

  defp build_section_form(data, "projects", index) do
    proj = Enum.at(data.projects || [], index)

    to_form(
      %{
        "name" => (proj && proj.name) || "",
        "description" => (proj && proj.description) || "",
        "url" => (proj && proj.url) || "",
        "highlights" => Enum.join((proj && proj.highlights) || [], "\n")
      },
      as: "section"
    )
  end

  defp build_section_form(data, "publications", index) do
    pub = Enum.at(data.publications || [], index)

    to_form(
      %{
        "title" => (pub && pub.title) || "",
        "publisher" => (pub && pub.publisher) || "",
        "url" => (pub && pub.url) || "",
        "date_year" => flex_date_field(pub && pub.date, :year),
        "date_month" => flex_date_field(pub && pub.date, :month)
      },
      as: "section"
    )
  end

  defp build_section_form(data, "volunteer_work", index) do
    vol = Enum.at(data.volunteer_work || [], index)

    to_form(
      %{
        "role" => (vol && vol.role) || "",
        "organization" => (vol && vol.organization) || "",
        "description" => (vol && vol.description) || "",
        "start_date_year" => flex_date_field(vol && vol.start_date, :year),
        "start_date_month" => flex_date_field(vol && vol.start_date, :month),
        "end_date_year" => flex_date_field(vol && vol.end_date, :year),
        "end_date_month" => flex_date_field(vol && vol.end_date, :month)
      },
      as: "section"
    )
  end

  defp build_section_form(data, "languages", index) do
    lang = Enum.at(data.languages || [], index)

    to_form(
      %{
        "name" => (lang && lang.name) || "",
        "fluency" => (lang && lang.fluency) || ""
      },
      as: "section"
    )
  end

  defp build_section_form(data, "awards", index) do
    award = Enum.at(data.awards || [], index)

    to_form(
      %{
        "title" => (award && award.title) || "",
        "issuer" => (award && award.issuer) || "",
        "summary" => (award && award.summary) || "",
        "date_year" => flex_date_field(award && award.date, :year),
        "date_month" => flex_date_field(award && award.date, :month)
      },
      as: "section"
    )
  end

  # Apply section edits to the data map

  defp apply_section_edit(data_map, "contact_info", _index, params) do
    existing = data_map["contact_info"] || %{}

    Map.put(data_map, "contact_info", %{
      "name" => params["name"],
      "email" => params["email"],
      "phone" => params["phone"],
      "location" => params["location"],
      "websites" => existing["websites"] || []
    })
  end

  defp apply_section_edit(data_map, "summary", _index, params) do
    Map.put(data_map, "summary", params["summary"])
  end

  defp apply_section_edit(data_map, "work_experience", index, params) do
    entries = data_map["work_experience"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "role" => params["role"],
        "company" => params["company"],
        "current" => params["current"] == "true",
        "start_date" => build_flex_date(params["start_date_year"], params["start_date_month"]),
        "end_date" => build_flex_date(params["end_date_year"], params["end_date_month"]),
        "accomplishments" => split_lines(params["accomplishments"])
      })

    Map.put(data_map, "work_experience", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "education", index, params) do
    entries = data_map["education"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "institution" => params["institution"],
        "degree" => params["degree"],
        "field" => params["field"],
        "start_date" => build_flex_date(params["start_date_year"], params["start_date_month"]),
        "end_date" => build_flex_date(params["end_date_year"], params["end_date_month"])
      })

    Map.put(data_map, "education", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "skills", index, params) do
    entries = data_map["skills"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "category" => params["category"],
        "skills" => split_comma(params["skills"])
      })

    Map.put(data_map, "skills", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "certifications", index, params) do
    entries = data_map["certifications"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "name" => params["name"],
        "issuer" => params["issuer"],
        "date" => build_flex_date(params["date_year"], params["date_month"])
      })

    Map.put(data_map, "certifications", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "projects", index, params) do
    entries = data_map["projects"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "name" => params["name"],
        "description" => params["description"],
        "url" => params["url"],
        "highlights" => split_lines(params["highlights"])
      })

    Map.put(data_map, "projects", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "publications", index, params) do
    entries = data_map["publications"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "title" => params["title"],
        "publisher" => params["publisher"],
        "url" => params["url"],
        "date" => build_flex_date(params["date_year"], params["date_month"])
      })

    Map.put(data_map, "publications", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "volunteer_work", index, params) do
    entries = data_map["volunteer_work"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "role" => params["role"],
        "organization" => params["organization"],
        "description" => params["description"],
        "start_date" => build_flex_date(params["start_date_year"], params["start_date_month"]),
        "end_date" => build_flex_date(params["end_date_year"], params["end_date_month"])
      })

    Map.put(data_map, "volunteer_work", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "languages", index, params) do
    entries = data_map["languages"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "name" => params["name"],
        "fluency" => params["fluency"]
      })

    Map.put(data_map, "languages", List.replace_at(entries, index, updated))
  end

  defp apply_section_edit(data_map, "awards", index, params) do
    entries = data_map["awards"] || []
    existing = Enum.at(entries, index) || %{}

    updated =
      Map.merge(existing, %{
        "title" => params["title"],
        "issuer" => params["issuer"],
        "summary" => params["summary"],
        "date" => build_flex_date(params["date_year"], params["date_month"])
      })

    Map.put(data_map, "awards", List.replace_at(entries, index, updated))
  end

  defp flex_date_field(nil, _field), do: ""
  defp flex_date_field(date, field), do: to_string(Map.get(date, field) || "")

  defp build_flex_date(year_str, month_str) do
    year = parse_int(year_str)
    month = parse_int(month_str)
    if year, do: %{"year" => year, "month" => month}, else: nil
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp split_lines(nil), do: []
  defp split_lines(""), do: []

  defp split_lines(text) do
    text |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp split_comma(nil), do: []
  defp split_comma(""), do: []

  defp split_comma(text) do
    text |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end
end
