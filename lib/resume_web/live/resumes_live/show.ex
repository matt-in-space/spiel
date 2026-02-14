defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, Feedback, JobPostings, Resumes}
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
    template_mod = Map.get(@templates, resume.template, Default)

    {:ok,
     assign(socket,
       user: user,
       resume: resume,
       template_mod: template_mod,
       template_css: template_mod.css(),
       template_form: to_form(%{"template" => resume.template}, as: "template"),
       targeting_form: build_targeting_form(resume),
       targeting_params: nil,
       fetching_url: false,
       feedback_messages: [],
       feedback_form: to_form(%{"message" => ""}, as: "feedback"),
       preview_data: nil,
       preview_explanation: nil,
       pending_directive: nil,
       processing_feedback: false,
       recording: false,
       transcribing: false,
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <.header>
          {@resume.title}
          <:subtitle>
            <span
              :if={@resume.job_posting_text || @resume.job_posting_url}
              class="badge badge-accent badge-sm"
            >
              Targeted
            </span>
            Created {Calendar.strftime(@resume.inserted_at, "%b %d, %Y")}
          </:subtitle>
          <:actions>
            <.link navigate={~p"/home"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left-micro" class="size-4" /> Back
            </.link>
            <.link href={~p"/resumes/#{@resume}/pdf"} class="btn btn-sm">
              <.icon name="hero-arrow-down-tray-micro" class="size-4" /> Download PDF
            </.link>
            <button
              phx-click="delete"
              data-confirm="Are you sure you want to delete this resume?"
              class="btn btn-ghost btn-sm text-error"
            >
              Delete
            </button>
          </:actions>
        </.header>

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

        <details class="collapse collapse-arrow bg-base-200">
          <summary class="collapse-title text-sm font-medium">
            Job Targeting
            <span
              :if={@resume.job_posting_text || @resume.job_posting_url}
              class="badge badge-accent badge-xs ml-2"
            >
              Active
            </span>
          </summary>
          <div class="collapse-content">
            <.form for={@targeting_form} phx-submit="save_targeting" phx-change="validate_targeting">
              <div class="space-y-3">
                <div class="flex gap-2 items-end">
                  <div class="flex-1">
                    <.input
                      field={@targeting_form[:job_posting_url]}
                      label="Job Posting URL (optional)"
                      type="url"
                      placeholder="https://..."
                    />
                  </div>
                  <button
                    type="button"
                    phx-click="fetch_url"
                    disabled={@fetching_url}
                    class="btn btn-sm btn-outline mb-2"
                  >
                    <span :if={@fetching_url} class="loading loading-spinner loading-xs"></span>
                    <.icon :if={!@fetching_url} name="hero-arrow-down-tray-micro" class="size-4" />
                    Fetch
                  </button>
                </div>
                <.input
                  field={@targeting_form[:job_posting_text]}
                  label="Job Description or Desired Role"
                  type="textarea"
                  placeholder="Paste a job description, describe your desired role, or fetch from URL above..."
                  rows="4"
                />
                <div class="flex gap-2">
                  <button type="submit" class="btn btn-sm btn-primary">Save Targeting</button>
                  <button
                    :if={@resume.job_posting_text || @resume.job_posting_url}
                    type="button"
                    phx-click="clear_targeting"
                    class="btn btn-sm btn-ghost"
                  >
                    Clear
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </details>

        <details :if={@resume.explanation} class="collapse collapse-arrow bg-base-200" open>
          <summary class="collapse-title text-sm font-medium">
            Writer's Notes
          </summary>
          <div class="collapse-content">
            <p class="text-sm">{@resume.explanation}</p>
          </div>
        </details>

        <details :if={@resume.tailoring_notes} class="collapse collapse-arrow bg-base-200" open>
          <summary class="collapse-title text-sm font-medium">
            Tailoring Notes
          </summary>
          <div class="collapse-content">
            <ul class="list-disc list-inside space-y-1 text-sm">
              <li :for={line <- parse_tailoring_notes(@resume.tailoring_notes)}>{line}</li>
            </ul>
          </div>
        </details>

        <div :if={@resume.data} class="space-y-4">
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
                placeholder="Suggest changes to your resume..."
                autocomplete="off"
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
          :if={@resume.data}
          class="mx-auto max-w-[8.5in] bg-white shadow-lg rounded-sm p-[0.85in] print:shadow-none print:p-0"
        >
          <div
            :if={@preview_data}
            class="flex items-center gap-2 mb-4 -mt-4 -mx-4 px-4 py-2 bg-warning/10 border-b border-warning/30"
          >
            <.icon name="hero-eye-micro" class="size-4 text-warning" />
            <span class="text-sm font-medium text-warning">Preview — unsaved changes</span>
          </div>
          {raw("<style>" <> @template_css <> "</style>")}
          {raw(render_template(@template_mod, display_data(@preview_data, @resume)))}
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

  @impl true
  def handle_event("validate_targeting", %{"targeting" => params}, socket) do
    {:noreply, assign(socket, targeting_params: params)}
  end

  @impl true
  def handle_event("save_targeting", %{"targeting" => params}, socket) do
    url = non_blank(params["job_posting_url"])
    text = non_blank(params["job_posting_text"])

    case Resumes.update_resume(socket.assigns.resume, %{
           job_posting_url: url,
           job_posting_text: text
         }) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(resume: resume, targeting_form: build_targeting_form(resume))
         |> put_flash(:info, "Job targeting saved.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save targeting.")}
    end
  end

  @impl true
  def handle_event("fetch_url", _params, socket) do
    url =
      (socket.assigns[:targeting_params]["job_posting_url"] ||
         socket.assigns.targeting_form.params["job_posting_url"])
      |> non_blank()

    if url do
      task = Task.async(fn -> JobPostings.fetch_text(url) end)

      {:noreply,
       socket
       |> assign(fetching_url: true)
       |> update(:task_refs, &Map.put(&1, task.ref, :fetch_url))}
    else
      {:noreply, put_flash(socket, :error, "Enter a URL first.")}
    end
  end

  @impl true
  def handle_event("clear_targeting", _params, socket) do
    case Resumes.update_resume(socket.assigns.resume, %{
           job_posting_url: nil,
           job_posting_text: nil,
           tailoring_notes: nil
         }) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(resume: resume, targeting_form: build_targeting_form(resume))
         |> put_flash(:info, "Job targeting cleared.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to clear targeting.")}
    end
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

    case Resumes.update_resume(socket.assigns.resume, %{
           data: preview_data,
           explanation: explanation
         }) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(
           resume: resume,
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
      {:fetch_url, {:ok, text}} ->
        params = Map.put(socket.assigns.targeting_form.params, "job_posting_text", text)

        {:noreply,
         socket
         |> assign(fetching_url: false, targeting_form: to_form(params, as: "targeting"))
         |> put_flash(:info, "Job posting content fetched.")}

      {:fetch_url, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(fetching_url: false)
         |> put_flash(:error, "Failed to fetch job posting. Try pasting the text instead.")}

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

  defp build_targeting_form(resume) do
    to_form(
      %{
        "job_posting_url" => resume.job_posting_url || "",
        "job_posting_text" => resume.job_posting_text || ""
      },
      as: "targeting"
    )
  end

  defp parse_tailoring_notes(notes) do
    notes
    |> String.split("\n")
    |> Enum.map(fn line -> String.replace_leading(line, "- ", "") |> String.trim() end)
    |> Enum.reject(&(&1 == ""))
  end

  defp non_blank(nil), do: nil

  defp non_blank(str) when is_binary(str) do
    case String.trim(str) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp display_data(nil, resume), do: resume.data

  defp display_data(preview_data, _resume) do
    %Resume.Resumes.ResumeData{}
    |> Resume.Resumes.ResumeData.changeset(preview_data)
    |> Ecto.Changeset.apply_changes()
  end

  defp process_feedback_message(socket, message) do
    messages = socket.assigns.feedback_messages ++ [%{role: :user, content: message}]
    user = Accounts.get_user!(socket.assigns.user.id)
    resume = socket.assigns.resume
    current_data = socket.assigns.preview_data || resume_data_to_map(resume.data)

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

    {facts, descriptions} =
      Enum.reduce(changes, {facts, []}, fn change, {facts_acc, descs} ->
        case change do
          %{"type" => "add", "text" => text} ->
            {facts_acc ++ [text], descs ++ ["Added fact: \"#{text}\""]}

          %{"type" => "update", "index" => idx, "text" => text} when is_integer(idx) ->
            zero_idx = idx - 1

            if zero_idx >= 0 and zero_idx < length(facts_acc) do
              {List.replace_at(facts_acc, zero_idx, text),
               descs ++ ["Updated fact ##{idx}: \"#{text}\""]}
            else
              {facts_acc, descs}
            end

          %{"type" => "remove", "index" => idx} when is_integer(idx) ->
            zero_idx = idx - 1

            if zero_idx >= 0 and zero_idx < length(facts_acc) do
              {List.delete_at(facts_acc, zero_idx), descs ++ ["Removed fact ##{idx}"]}
            else
              {facts_acc, descs}
            end

          _ ->
            {facts_acc, descs}
        end
      end)

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

  defp resume_data_to_map(nil), do: %{}

  defp resume_data_to_map(data) do
    data
    |> Ecto.embedded_dump(:json)
    |> Jason.encode!()
    |> Jason.decode!()
  end
end
