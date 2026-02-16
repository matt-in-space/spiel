defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, Feedback, Resumes}
  alias ResumeWeb.ResumeTemplates.Default

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive
  }

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)
    versions = Resumes.list_versions(resume.id)
    current_version = List.first(versions)
    template_mod = Map.get(@templates, resume.template, Default)

    {:ok,
     assign(socket,
       user: user,
       resume: resume,
       versions: versions,
       current_version: current_version,
       template_mod: template_mod,
       template_css: template_mod.css(),
       template_form: to_form(%{"template" => resume.template}, as: "template"),
       feedback_messages: [],
       feedback_form: to_form(%{"message" => ""}, as: "feedback"),
       preview_data: nil,
       preview_explanation: nil,
       pending_directive: nil,
       processing_feedback: false,
       recording: false,
       transcribing: false,
       editing_title: false,
       title_form: to_form(%{"title" => resume.title}, as: "title"),
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

  defp latest_version?(versions, current_version) do
    current_version != nil and current_version.version == max_version(versions)
  end

  defp max_version([]), do: 0
  defp max_version([v | _]), do: v.version

  defp version_data(current_version) do
    if current_version, do: Resumes.dump_version_data(current_version), else: nil
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:is_latest, latest_version?(assigns.versions, assigns.current_version))
      |> assign(:current_data, version_data(assigns.current_version))

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
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
              <.link :if={@current_version} href={~p"/resumes/#{@resume}/pdf"} class="btn btn-sm">
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
            <div
              :if={@resume.job_posting_text || @resume.job_posting_url}
              class="tooltip tooltip-bottom"
              data-tip={
                String.slice(@resume.job_posting_text || @resume.job_posting_url || "", 0, 200)
              }
            >
              <span class="badge badge-accent badge-sm cursor-default">Targeted</span>
            </div>
            <span>Created {Calendar.strftime(@resume.inserted_at, "%b %d, %Y")}</span>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <.form for={@template_form} phx-change="change_template" class="flex items-center gap-2">
            <label class="text-sm font-medium">Template:</label>
            <.input
              field={@template_form[:template]}
              type="select"
              options={[
                {"Default", "default"},
                {"Mono", "mono"},
                {"Fresh", "fresh"},
                {"Executive", "executive"}
              ]}
            />
          </.form>
        </div>

        <div :if={length(@versions) > 1} class="flex items-center gap-2">
          <label class="text-sm font-medium">Version:</label>
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

        <details
          :if={@current_version && @current_version.explanation}
          class="collapse collapse-arrow bg-base-200"
          open
        >
          <summary class="collapse-title text-sm font-medium">
            Notes
          </summary>
          <div class="collapse-content">
            <p class="text-sm">{@current_version.explanation}</p>
          </div>
        </details>

        <div :if={@current_data && @is_latest} class="space-y-4">
          <div
            :if={@feedback_messages != []}
            id="feedback-messages"
            phx-hook=".ChatScroll"
            class="max-h-80 overflow-y-auto space-y-3 p-3 bg-base-200 rounded-lg"
          >
            <div
              :for={msg <- @feedback_messages}
              class={[
                "chat",
                if(msg.role == :user, do: "chat-end", else: "chat-start")
              ]}
            >
              <div class={[
                "chat-bubble",
                if(msg.role == :assistant, do: "chat-bubble-primary", else: "")
              ]}>
                {msg.content}
              </div>
            </div>

            <div :if={@pending_directive} class="chat chat-start">
              <div class="chat-bubble chat-bubble-primary">
                <p class="mb-2">Should this always apply?</p>
                <p class="text-xs opacity-80 mb-3">"{@pending_directive}"</p>
                <div class="flex gap-2">
                  <button phx-click="always_directive" class="btn btn-xs btn-accent">Always</button>
                  <button phx-click="just_this_resume" class="btn btn-xs btn-ghost">
                    Just this resume
                  </button>
                </div>
              </div>
            </div>

            <div :if={@processing_feedback} class="chat chat-start">
              <div class="chat-bubble chat-bubble-primary">
                <span class="loading loading-dots loading-sm"></span>
              </div>
            </div>
          </div>

          <div
            id="audio-recorder"
            phx-hook=".AudioRecorder"
            phx-update="ignore"
            data-recording={to_string(@recording)}
          >
          </div>

          <div :if={@transcribing} class="flex items-center gap-2 text-sm">
            <span class="loading loading-spinner loading-xs"></span> Transcribing...
          </div>

          <.form
            for={@feedback_form}
            phx-submit="send_feedback"
            phx-change="validate_feedback"
            class="flex items-end gap-2"
          >
            <div class="flex-1">
              <.input
                field={@feedback_form[:message]}
                type="textarea"
                placeholder="Suggest changes to your resume..."
                autocomplete="off"
                rows="1"
                phx-hook=".AutoGrow"
                class="w-full textarea resize-none overflow-hidden"
              />
            </div>
            <%= if @recording do %>
              <button type="button" phx-click="stop_recording" class="btn btn-error btn-sm">
                <.icon name="hero-stop-solid" class="size-4" />
              </button>
            <% else %>
              <button type="button" phx-click="start_recording" class="btn btn-ghost btn-sm">
                <.icon name="hero-microphone-solid" class="size-4" />
              </button>
            <% end %>
            <button
              type="submit"
              class="btn btn-primary btn-sm"
              disabled={@processing_feedback || @transcribing}
            >
              <.icon name="hero-paper-airplane-solid" class="size-4" />
            </button>
          </.form>

          <div :if={@preview_data} class="flex items-center gap-2">
            <button phx-click="confirm_changes" class="btn btn-primary btn-sm">
              <.icon name="hero-check-micro" class="size-4" /> Confirm Changes
            </button>
            <button phx-click="revert_changes" class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-uturn-left-micro" class="size-4" /> Revert
            </button>
          </div>
        </div>

        <div
          :if={@current_data}
          class="mx-auto max-w-[8.5in] bg-white border border-base-300 rounded-sm p-[0.85in] print:border-none print:p-0"
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoGrow">
      export default {
        mounted() {
          this.el.addEventListener("input", () => this.resize());
          this.resize();
        },
        updated() {
          this.resize();
        },
        resize() {
          this.el.style.height = "auto";
          this.el.style.height = this.el.scrollHeight + "px";
        },
      };
    </script>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChatScroll">
      export default {
        mounted() {
          this.scrollToBottom();
        },
        updated() {
          this.scrollToBottom();
        },
        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight;
        },
      };
    </script>
    """
  end

  @impl true
  def handle_event("select_version", %{"version" => version_str}, socket) do
    version_number = String.to_integer(version_str)
    current_version = Resumes.get_version!(socket.assigns.resume.id, version_number)

    {:noreply,
     assign(socket,
       current_version: current_version,
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
  def handle_event("change_template", %{"template" => %{"template" => template}}, socket) do
    {:ok, resume} = Resumes.update_resume(socket.assigns.resume, %{template: template})
    template_mod = Map.get(@templates, template, Default)

    {:noreply,
     socket
     |> assign(
       resume: resume,
       template_mod: template_mod,
       template_css: template_mod.css(),
       template_form: to_form(%{"template" => template}, as: "template")
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

        {:noreply,
         socket
         |> assign(
           versions: versions,
           current_version: version,
           preview_data: nil,
           preview_explanation: nil
         )
         |> put_flash(:info, "Changes saved.")}

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
       pending_directive: nil
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
         |> assign(
           user: user,
           pending_directive: nil,
           feedback_messages:
             socket.assigns.feedback_messages ++
               [%{role: :assistant, content: "Saved as a standing directive: \"#{directive}\""}]
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save directive.")}
    end
  end

  @impl true
  def handle_event("just_this_resume", _params, socket) do
    {:noreply,
     assign(socket,
       pending_directive: nil,
       feedback_messages:
         socket.assigns.feedback_messages ++
           [%{role: :assistant, content: "Applied to this resume only."}]
     )}
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
    audio_binary = Base.decode64!(data)

    task =
      Task.async(fn ->
        Resume.Transcription.transcribe(audio_binary, content_type: type)
      end)

    {:noreply,
     socket
     |> assign(recording: false, transcribing: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :transcribe_feedback))}
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

      {:transcribe_feedback, {:ok, transcript}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> process_feedback_message(transcript)}

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
    messages = socket.assigns.feedback_messages ++ [%{role: :user, content: message}]
    user = Accounts.get_user!(socket.assigns.user.id)
    current_version = socket.assigns.current_version
    current_data = socket.assigns.preview_data || version_data_to_map(current_version)

    task =
      Task.async(fn ->
        Feedback.process_feedback(current_data, user, message, history: messages)
      end)

    socket
    |> assign(
      feedback_messages: messages,
      processing_feedback: true,
      feedback_form: to_form(%{"message" => ""}, as: "feedback"),
      user: user
    )
    |> update(:task_refs, &Map.put(&1, task.ref, :feedback))
  end

  defp handle_feedback_result(socket, result) do
    messages =
      socket.assigns.feedback_messages ++
        [%{role: :assistant, content: result.explanation}]

    socket = assign(socket, processing_feedback: false, feedback_messages: messages)

    # Set preview data
    socket = assign(socket, preview_data: result.data, preview_explanation: result.explanation)

    # Handle classification
    socket =
      case result.classification do
        :directive when is_binary(result.directive) ->
          user = Accounts.get_user!(socket.assigns.user.id)
          directives = (user.directives || []) ++ [result.directive]

          case Accounts.update_user_directives(user, directives) do
            {:ok, user} ->
              assign(socket,
                user: user,
                feedback_messages:
                  socket.assigns.feedback_messages ++
                    [
                      %{
                        role: :assistant,
                        content: "Saved as a standing directive: \"#{result.directive}\""
                      }
                    ]
              )

            {:error, _} ->
              socket
          end

        :ambiguous when is_binary(result.directive) ->
          assign(socket, pending_directive: result.directive)

        _ ->
          socket
      end

    # Handle fact changes
    apply_fact_changes(socket, result.fact_changes)
  end

  defp apply_fact_changes(socket, []), do: socket

  defp apply_fact_changes(socket, changes) do
    user = Accounts.get_user!(socket.assigns.user.id)
    facts = user.facts || []

    {facts, descriptions} = Resume.Facts.apply_changes(facts, changes)

    case Accounts.update_user_facts(user, facts) do
      {:ok, user} ->
        if descriptions != [] do
          msg = Enum.join(descriptions, ". ") <> "."

          assign(socket,
            user: user,
            feedback_messages:
              socket.assigns.feedback_messages ++
                [%{role: :assistant, content: msg}]
          )
        else
          assign(socket, user: user)
        end

      {:error, _} ->
        socket
    end
  end

  defp version_data_to_map(nil), do: %{}

  defp version_data_to_map(%{data: data}) do
    data
    |> Jason.encode!()
    |> Jason.decode!()
  end
end
