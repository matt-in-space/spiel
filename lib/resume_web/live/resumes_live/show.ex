defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, Feedback, Resumes, Retry}
  alias ResumeWeb.ResumeTemplates.Default

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive
  }

  @template_options [
    {"Default", "default"},
    {"Mono", "mono"},
    {"Fresh", "fresh"},
    {"Executive", "executive"}
  ]

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)
    versions = Resumes.list_versions(resume.id)
    current_version = List.first(versions)
    template_mod = Map.get(@templates, resume.template, Default)
    current_data = version_data(current_version)

    {:ok,
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
       sidebar_open: false,
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

  defp version_data(current_version) do
    if current_version, do: Resumes.dump_version_data(current_version), else: nil
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :current_data, version_data(assigns.current_version))

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="drawer drawer-end">
        <input
          id="sidebar-toggle"
          type="checkbox"
          class="drawer-toggle"
          checked={@sidebar_open}
          phx-click="toggle_sidebar"
        />
        <div class="drawer-content space-y-6">
          <label
            for="sidebar-toggle"
            class="fixed right-0 top-1/2 -translate-y-1/2 z-10 bg-base-200 hover:bg-base-300 transition-colors rounded-l-lg px-2.5 py-5 cursor-pointer shadow-md"
          >
            <.icon name="hero-chevron-left-micro" class="size-5" />
          </label>

          <div class="space-y-1">
            <div class="text-sm breadcrumbs p-0">
              <ul>
                <li><.link navigate={~p"/home"}>Home</.link></li>
                <li>{@resume.title}</li>
              </ul>
            </div>

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
            </div>
          </div>

          <div :if={@current_data} class="space-y-4">
            <div
              id="audio-recorder"
              phx-hook=".AudioRecorder"
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
                for={@feedback_form}
                phx-submit="send_feedback"
                phx-change="validate_feedback"
                class="rounded-lg border border-base-300 focus-within:border-primary transition-colors"
              >
                <textarea
                  id={@feedback_form[:message].id}
                  name={@feedback_form[:message].name}
                  placeholder="Suggest changes to your resume..."
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
                    disabled={@transcribing}
                  >
                    <.icon name="hero-paper-airplane-solid" class="size-3.5" />
                  </button>
                </div>
              </.form>
            </div>
          </div>

          <div
            :if={@current_data}
            class={[
              "mx-auto max-w-[8.5in] bg-white border border-base-300 rounded-sm print:border-none print:p-0",
              if(@resume.template == "executive", do: "p-0 overflow-hidden", else: "p-[0.85in]")
            ]}
          >
            <div
              :if={@preview_data}
              class="flex items-center gap-2 mb-4 -mt-4 -mx-4 px-4 py-2 bg-warning/10 border-b border-warning/30"
            >
              <.icon name="hero-eye-micro" class="size-4 text-warning" />
              <span class="text-sm font-medium text-warning">Preview — unsaved changes</span>
            </div>
            {raw("<style>" <> @template_css <> "</style>")}
            {raw(render_template(@template_mod, display_data(@preview_data, @current_data)))}
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

      task =
        Task.async(fn ->
          Retry.with_retry(fn ->
            Resume.Transcription.transcribe(audio_binary, content_type: type)
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

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:feedback, {:ok, result}} ->
        {:noreply, handle_feedback_result(socket, result)}

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
      full_bleed? = key == "executive"
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
end
