defmodule ResumeWeb.OnboardingLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Documents, Facts, Interview}

  @steps [:contact, :import, :interview, :recap]

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)

    if Accounts.onboarding_completed?(user) do
      {:ok, redirect(socket, to: ~p"/home")}
    else
      profile_data = Map.merge(%{"email" => user.email}, user.default_resume_data)

      {:ok,
       socket
       |> assign(
         user: user,
         step: :contact,
         profile_form: to_form(profile_data, as: "profile"),
         profile_data: profile_data,
         # import
         text_form: to_form(%{"text" => ""}, as: "paste"),
         import_status: nil,
         import_fact_count: 0,
         # interview
         messages: [],
         interview_facts: [],
         turn_number: 0,
         input_form: to_form(%{"message" => ""}, as: "chat"),
         recording: false,
         transcribing: false,
         interview_processing: false,
         # recap
         recap_text: nil,
         recap_loading: false,
         recap_input_form: to_form(%{"correction" => ""}, as: "recap"),
         # shared
         all_facts: user.facts || [],
         task_refs: %{}
       )
       |> allow_upload(:documents,
         accept: ~w(.txt .pdf),
         max_entries: 5,
         max_file_size: 5_000_000
       )}
    end
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
      <div class="space-y-6 max-w-2xl mx-auto">
        <.steps_indicator current={@step} />

        <.contact_step
          :if={@step == :contact}
          profile_form={@profile_form}
        />

        <.import_step
          :if={@step == :import}
          text_form={@text_form}
          uploads={@uploads}
          import_status={@import_status}
          import_fact_count={@import_fact_count}
        />

        <.interview_step
          :if={@step == :interview}
          messages={@messages}
          input_form={@input_form}
          recording={@recording}
          transcribing={@transcribing}
          interview_processing={@interview_processing}
        />

        <.recap_step
          :if={@step == :recap}
          recap_text={@recap_text}
          recap_loading={@recap_loading}
          recap_input_form={@recap_input_form}
        />
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

  # Step components

  defp contact_step(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-2">Tell us about yourself</h1>
      <p class="text-sm opacity-70 mb-6">
        This information will appear on your resume's contact section.
      </p>

      <.form for={@profile_form} phx-change="validate_profile" phx-submit="save_profile">
        <.input field={@profile_form[:name]} label="Full Name" required />
        <.input field={@profile_form[:email]} label="Email" type="email" />
        <.input field={@profile_form[:phone]} label="Phone" type="tel" />
        <.input field={@profile_form[:location]} label="Location" placeholder="City, State" />
        <.input
          field={@profile_form[:website]}
          label="Website"
          type="url"
          placeholder="https://"
        />
        <.input
          field={@profile_form[:linkedin]}
          label="LinkedIn"
          placeholder="https://linkedin.com/in/..."
        />
        <.input
          field={@profile_form[:github]}
          label="GitHub"
          placeholder="https://github.com/..."
        />
        <.input
          field={@profile_form[:career_goal]}
          type="textarea"
          label="Career Goal"
          placeholder="e.g. I'm looking for a senior engineering role focused on system design"
        />

        <div class="mt-6">
          <button type="submit" class="btn btn-primary">
            Next <.icon name="hero-arrow-right-micro" class="size-4" />
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp import_step(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-2">Import Your Experience</h1>
      <p class="text-sm opacity-70 mb-6">
        Upload resumes, LinkedIn exports, or paste text to quickly import your career history.
      </p>

      <div :if={@import_status == :processing} class="flex flex-col items-center gap-3 py-12">
        <span class="loading loading-spinner loading-lg"></span>
        <p class="text-sm opacity-70">Extracting facts from your documents...</p>
      </div>

      <div :if={@import_status == :done} class="text-center py-8">
        <div class="text-4xl mb-3">
          <.icon name="hero-check-circle" class="size-12 text-success mx-auto" />
        </div>
        <p class="text-lg font-medium mb-1">
          Extracted {@import_fact_count} facts
        </p>
        <p class="text-sm opacity-70 mb-6">
          These will be used alongside your interview responses.
        </p>
        <button phx-click="advance_from_import" class="btn btn-primary">
          Continue <.icon name="hero-arrow-right-micro" class="size-4" />
        </button>
      </div>

      <div :if={@import_status == nil}>
        <.form for={@text_form} phx-change="validate_import" phx-submit="submit_import">
          <div class="space-y-4">
            <div
              class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center"
              phx-drop-target={@uploads.documents.ref}
            >
              <.icon name="hero-document-arrow-up" class="size-8 mx-auto opacity-50 mb-2" />
              <p class="text-sm opacity-70 mb-2">Drag & drop files here (.txt, .pdf), or</p>
              <.live_file_input
                upload={@uploads.documents}
                class="file-input file-input-bordered file-input-sm"
              />

              <div
                :for={entry <- @uploads.documents.entries}
                class="mt-3 flex items-center gap-2 justify-center"
              >
                <.icon name="hero-document-text" class="size-4" />
                <span class="text-sm">{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  class="btn btn-ghost btn-xs text-error"
                >
                  <.icon name="hero-x-mark-micro" class="size-4" />
                </button>
              </div>

              <div
                :for={err <- upload_errors(@uploads.documents)}
                class="text-error text-sm mt-2"
              >
                {upload_error_message(err)}
              </div>
            </div>

            <.input
              field={@text_form[:text]}
              type="textarea"
              label="Or paste text"
              placeholder="Paste your resume, LinkedIn summary, or any career-related text..."
              rows="6"
            />

            <div class="flex items-center gap-3">
              <button type="submit" class="btn btn-primary">
                Import <.icon name="hero-arrow-right-micro" class="size-4" />
              </button>
              <button type="button" phx-click="skip_import" class="btn btn-ghost">
                Skip
              </button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp interview_step(assigns) do
    ~H"""
    <div class="flex flex-col h-[60vh]">
      <h1 class="text-2xl font-bold mb-2">Career Interview</h1>
      <p class="text-sm opacity-70 mb-4">
        Tell me about your career. I'll ask follow-up questions to build your profile.
      </p>

      <div
        id="chat-messages"
        phx-hook=".ChatScroll"
        class="flex-1 overflow-y-auto space-y-3 mb-4 p-2"
      >
        <div
          :for={msg <- @messages}
          class={[
            "chat",
            if(msg.role == :assistant, do: "chat-start", else: "chat-end")
          ]}
        >
          <div class={[
            "chat-bubble",
            if(msg.role == :assistant, do: "chat-bubble-primary", else: "")
          ]}>
            {msg.content}
          </div>
        </div>

        <div :if={@interview_processing} class="chat chat-start">
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

      <div :if={@transcribing} class="flex items-center gap-2 text-sm mb-2">
        <span class="loading loading-spinner loading-xs"></span> Transcribing...
      </div>

      <.form for={@input_form} phx-submit="send_message" class="flex items-end gap-2">
        <div class="flex-1">
          <.input
            field={@input_form[:message]}
            placeholder="Type your response..."
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
          disabled={@interview_processing || @transcribing}
        >
          <.icon name="hero-paper-airplane-solid" class="size-4" />
        </button>
      </.form>

      <div class="flex items-center gap-3 mt-3">
        <button phx-click="interview_done" class="btn btn-ghost btn-sm">
          I'm done
        </button>
        <button phx-click="skip_interview" class="btn btn-ghost btn-sm">
          Skip
        </button>
      </div>
    </div>
    """
  end

  defp recap_step(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold mb-2">Your Career Summary</h1>
      <p class="text-sm opacity-70 mb-6">
        Here's what we know about you. Add corrections below if anything is missing or wrong.
      </p>

      <div :if={@recap_loading} class="flex flex-col items-center gap-3 py-12">
        <span class="loading loading-spinner loading-lg"></span>
        <p class="text-sm opacity-70">Generating your summary...</p>
      </div>

      <div :if={!@recap_loading && @recap_text} class="card bg-base-200 p-6 mb-6">
        <p class="whitespace-pre-wrap text-sm">{@recap_text}</p>
      </div>

      <div :if={!@recap_loading && !@recap_text} class="card bg-base-200 p-6 mb-6">
        <p class="text-sm opacity-50">No facts collected yet. You can always add more later.</p>
      </div>

      <.form
        :if={!@recap_loading}
        for={@recap_input_form}
        phx-submit="submit_correction"
        class="flex items-end gap-2 mb-6"
      >
        <div class="flex-1">
          <.input
            field={@recap_input_form[:correction]}
            placeholder="Add a correction or missing detail..."
            autocomplete="off"
          />
        </div>
        <button type="submit" class="btn btn-ghost btn-sm">
          Add
        </button>
      </.form>

      <button
        :if={!@recap_loading}
        phx-click="complete_onboarding"
        class="btn btn-primary"
      >
        Complete Setup <.icon name="hero-check-micro" class="size-4" />
      </button>
    </div>
    """
  end

  defp upload_error_message(:too_large), do: "File is too large (max 5 MB)"
  defp upload_error_message(:not_accepted), do: "Only .txt and .pdf files are accepted"
  defp upload_error_message(:too_many_files), do: "Maximum 5 files"
  defp upload_error_message(_), do: "Upload error"

  # Steps indicator

  defp steps_indicator(assigns) do
    assigns = assign(assigns, steps: @steps)

    ~H"""
    <ul class="steps steps-horizontal w-full mb-4">
      <li
        :for={step <- @steps}
        class={["step", step_class(step, @current)]}
      >
        <span class="text-xs hidden sm:inline">{step_label(step)}</span>
      </li>
    </ul>
    """
  end

  defp step_class(step, current) do
    step_idx = Enum.find_index(@steps, &(&1 == step))
    current_idx = Enum.find_index(@steps, &(&1 == current))
    if step_idx <= current_idx, do: "step-primary", else: ""
  end

  defp step_label(:contact), do: "Contact"
  defp step_label(:import), do: "Import"
  defp step_label(:interview), do: "Interview"
  defp step_label(:recap), do: "Recap"

  # === Event handlers ===

  # Contact step events

  @impl true
  def handle_event("validate_profile", %{"profile" => params}, socket) do
    {:noreply, assign(socket, profile_form: to_form(params, as: "profile"))}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_profile(user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(user: user, profile_data: params, step: :import)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(profile_form: to_form(params, as: "profile"))
         |> put_flash(:error, "Please fill in your name.")}
    end
  end

  # Import step events

  @impl true
  def handle_event("validate_import", %{"paste" => params}, socket) do
    {:noreply, assign(socket, text_form: to_form(params, as: "paste"))}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :documents, ref)}
  end

  @impl true
  def handle_event("submit_import", %{"paste" => %{"text" => pasted_text}}, socket) do
    results =
      consume_uploaded_entries(socket, :documents, fn %{path: path}, entry ->
        case Documents.extract_text(path, entry.client_type) do
          {:ok, text} -> {:ok, text}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)

    extraction_error =
      Enum.find_value(results, fn
        {:error, reason} -> reason
        _ -> nil
      end)

    file_texts =
      results
      |> Enum.reject(&match?({:error, _}, &1))

    pasted_text = String.trim(pasted_text)

    all_texts =
      file_texts
      |> Kernel.++(if pasted_text == "", do: [], else: [pasted_text])

    cond do
      extraction_error != nil ->
        {:noreply, put_flash(socket, :error, "Failed to read file: #{extraction_error}")}

      all_texts == [] ->
        {:noreply, put_flash(socket, :error, "Please upload a file or paste some text.")}

      true ->
        combined = Enum.join(all_texts, "\n\n")

        task =
          Task.async(fn ->
            Facts.extract([combined], "uploaded documents about their career",
              existing_facts: socket.assigns.all_facts
            )
          end)

        {:noreply,
         socket
         |> assign(import_status: :processing)
         |> update(:task_refs, &Map.put(&1, task.ref, {:import_extract, :batch}))}
    end
  end

  @impl true
  def handle_event("skip_import", _params, socket) do
    {:noreply, advance_to_interview(socket)}
  end

  @impl true
  def handle_event("advance_from_import", _params, socket) do
    {:noreply, advance_to_interview(socket)}
  end

  # Interview step events

  @impl true
  def handle_event("send_message", %{"chat" => %{"message" => message}}, socket) do
    message = String.trim(message)

    if message == "" do
      {:noreply, socket}
    else
      {:noreply, process_user_message(socket, message)}
    end
  end

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
     |> update(:task_refs, &Map.put(&1, task.ref, {:transcribe, :interview}))}
  end

  @impl true
  def handle_event("recording_error", %{"reason" => reason}, socket) do
    {:noreply,
     socket
     |> assign(:recording, false)
     |> put_flash(:error, "Recording failed: #{reason}")}
  end

  @impl true
  def handle_event("interview_done", _params, socket) do
    {:noreply, advance_to_recap(socket)}
  end

  @impl true
  def handle_event("skip_interview", _params, socket) do
    {:noreply, advance_to_recap(socket)}
  end

  # Recap step events

  @impl true
  def handle_event("submit_correction", %{"recap" => %{"correction" => correction}}, socket) do
    correction = String.trim(correction)

    if correction == "" do
      {:noreply, socket}
    else
      task =
        Task.async(fn ->
          Facts.extract([correction], "a user correction during onboarding recap",
            existing_facts: socket.assigns.all_facts
          )
        end)

      {:noreply,
       socket
       |> assign(recap_input_form: to_form(%{"correction" => ""}, as: "recap"))
       |> update(:task_refs, &Map.put(&1, task.ref, {:correction, nil}))}
    end
  end

  @impl true
  def handle_event("complete_onboarding", _params, socket) do
    user = socket.assigns.user
    profile_data = socket.assigns.profile_data
    facts = socket.assigns.all_facts

    case Accounts.complete_onboarding(user, profile_data, facts) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome! Your profile is set up.")
         |> redirect(to: ~p"/home")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  # === Task results ===

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {{:import_extract, :batch}, {:ok, facts}} ->
        {:noreply,
         socket
         |> update(:all_facts, &(&1 ++ facts))
         |> assign(import_status: :done, import_fact_count: length(facts))}

      {{:import_extract, :batch}, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(import_status: nil)
         |> put_flash(:error, "Failed to extract facts. Please try again.")}

      {{:interview_opening, nil}, {:ok, question}} ->
        {:noreply,
         socket
         |> assign(
           messages: [%{role: :assistant, content: question}],
           interview_processing: false
         )}

      {{:interview_opening, nil}, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(
           messages: [
             %{
               role: :assistant,
               content: "Tell me about your current or most recent role — what do you do?"
             }
           ],
           interview_processing: false
         )}

      {{:interview_turn, _n},
       {:ok, %{facts: new_facts, question: question, should_wrap_up: wrap}}} ->
        messages = socket.assigns.messages ++ [%{role: :assistant, content: question}]

        socket =
          socket
          |> update(:all_facts, &(&1 ++ new_facts))
          |> update(:interview_facts, &(&1 ++ new_facts))
          |> assign(messages: messages, interview_processing: false)

        if wrap do
          {:noreply, advance_to_recap(socket)}
        else
          {:noreply, socket}
        end

      {{:interview_turn, _n}, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(interview_processing: false)
         |> put_flash(:error, "Something went wrong. Please try again.")}

      {{:transcribe, :interview}, {:ok, transcript}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> process_user_message(transcript)}

      {{:transcribe, :interview}, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> put_flash(:error, "Transcription failed. Please try typing instead.")}

      {{:recap, nil}, {:ok, recap_text}} ->
        {:noreply, assign(socket, recap_text: recap_text, recap_loading: false)}

      {{:recap, nil}, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(recap_loading: false)
         |> put_flash(:error, "Failed to generate summary.")}

      {{:correction, nil}, {:ok, new_facts}} ->
        {:noreply,
         socket
         |> update(:all_facts, &(&1 ++ new_facts))
         |> put_flash(:info, "Added #{length(new_facts)} fact(s).")}

      {{:correction, nil}, {:error, _reason}} ->
        {:noreply, put_flash(socket, :error, "Failed to process correction.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  # === Private helpers ===

  defp advance_to_interview(socket) do
    profile = socket.assigns.user.default_resume_data || %{}

    task =
      Task.async(fn ->
        Interview.opening_question(socket.assigns.all_facts, profile)
      end)

    socket
    |> assign(step: :interview, interview_processing: true)
    |> update(:task_refs, &Map.put(&1, task.ref, {:interview_opening, nil}))
  end

  defp advance_to_recap(socket) do
    profile = socket.assigns.user.default_resume_data || %{}

    if socket.assigns.all_facts == [] do
      socket
      |> assign(step: :recap, recap_loading: false, recap_text: nil)
    else
      task =
        Task.async(fn ->
          Interview.generate_recap(socket.assigns.all_facts, profile)
        end)

      socket
      |> assign(step: :recap, recap_loading: true)
      |> update(:task_refs, &Map.put(&1, task.ref, {:recap, nil}))
    end
  end

  defp process_user_message(socket, message) do
    turn = socket.assigns.turn_number + 1
    messages = socket.assigns.messages ++ [%{role: :user, content: message}]
    profile = socket.assigns.user.default_resume_data || %{}

    history =
      Enum.map(messages, fn msg ->
        %{role: msg.role, content: msg.content}
      end)

    task =
      Task.async(fn ->
        Interview.process_turn(
          message,
          history,
          socket.assigns.all_facts,
          turn,
          profile
        )
      end)

    socket
    |> assign(
      messages: messages,
      turn_number: turn,
      interview_processing: true,
      input_form: to_form(%{"message" => ""}, as: "chat")
    )
    |> update(:task_refs, &Map.put(&1, task.ref, {:interview_turn, turn}))
  end
end
