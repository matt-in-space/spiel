defmodule ResumeWeb.OnboardingLive do
  use ResumeWeb, :live_view

  alias Resume.Accounts

  @steps [:profile, :current_role, :previous_roles, :education, :skills, :review]

  @step_config %{
    current_role: %{
      title: "Current / Most Recent Role",
      prompt:
        "Tell me about your current or most recent role. What's your title, company, and what do you do day-to-day? What are you most proud of accomplishing?",
      skippable: false
    },
    previous_roles: %{
      title: "Previous Experience",
      prompt:
        "Tell me about your previous roles. Where did you work before, what did you do, and what did you accomplish?",
      skippable: true
    },
    education: %{
      title: "Education",
      prompt:
        "Tell me about your education. Where did you study, what did you study, and when did you graduate?",
      skippable: true
    },
    skills: %{
      title: "Skills & Extras",
      prompt:
        "What technical skills, tools, certifications, or other qualifications do you have? Anything else you'd like to include on your resume?",
      skippable: true
    }
  }

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)

    if Accounts.onboarding_completed?(user) do
      {:ok, redirect(socket, to: ~p"/")}
    else
      profile_data = Map.merge(%{"email" => user.email}, user.default_resume_data)

      {:ok,
       assign(socket,
         user: user,
         step: :profile,
         profile_form: to_form(profile_data, as: "profile"),
         profile_data: profile_data,
         recording: false,
         recordings: [],
         task_refs: %{},
         pending_facts: [],
         extracting: false
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
      <div class="space-y-6">
        <.steps_indicator current={@step} />

        <div :if={@step == :profile}>
          <h1 class="text-2xl font-bold mb-2">Tell us about yourself</h1>
          <p class="text-sm opacity-70 mb-6">
            This information will appear on your resume's contact section.
          </p>

          <.form for={@profile_form} phx-change="validate_profile" phx-submit="save_profile">
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

        <div :if={@step in [:current_role, :previous_roles, :education, :skills]}>
          <h1 class="text-2xl font-bold mb-2">{step_config(@step).title}</h1>
          <p class="text-sm opacity-70 mb-6">{step_config(@step).prompt}</p>

          <div
            id="audio-recorder"
            phx-hook=".AudioRecorder"
            phx-update="ignore"
            data-recording={to_string(@recording)}
          >
          </div>

          <div class="flex items-center gap-4 mb-6">
            <%= if @recording do %>
              <button phx-click="stop_recording" class="btn btn-error">
                <.icon name="hero-stop-solid" class="size-5" /> Stop Recording
              </button>
              <span class="text-sm animate-pulse">Recording...</span>
            <% else %>
              <button phx-click="start_recording" class="btn btn-primary">
                <.icon name="hero-microphone-solid" class="size-5" /> Record
              </button>
            <% end %>
          </div>

          <div :if={@recordings != []} class="space-y-3 mb-6">
            <ul class="space-y-2">
              <li
                :for={rec <- @recordings}
                class="card bg-base-200 p-4 flex flex-col gap-2"
              >
                <div class="flex items-center gap-4">
                  <.icon name="hero-musical-note" class="size-5 text-primary" />
                  <div class="flex-1">
                    <p class="text-sm font-medium">Recording #{rec.id}</p>
                    <p class="text-xs opacity-70">
                      {format_size(rec.size)} &middot; {format_timestamp(rec.timestamp)}
                    </p>
                  </div>
                </div>

                <div :if={rec.status == :transcribing} class="flex items-center gap-2 text-sm">
                  <span class="loading loading-spinner loading-xs"></span> Transcribing...
                </div>

                <div :if={rec.status == :done} class="text-sm bg-base-100 rounded p-3">
                  <p class="font-medium text-xs opacity-50 mb-1">Transcript</p>
                  <p>{rec.transcript}</p>
                </div>

                <div :if={rec.status == :error} class="text-sm text-error">
                  Transcription failed. Please try again.
                </div>
              </li>
            </ul>
          </div>

          <div :if={@extracting} class="flex items-center gap-2 text-sm mb-4">
            <span class="loading loading-spinner loading-sm"></span>
            Extracting facts from your recording...
          </div>

          <div class="flex items-center gap-3">
            <button
              phx-click="next_step"
              class="btn btn-primary"
              disabled={any_transcribing?(@recordings) || @extracting}
            >
              Next <.icon name="hero-arrow-right-micro" class="size-4" />
            </button>
            <button
              :if={step_config(@step).skippable}
              phx-click="skip_step"
              class="btn btn-ghost"
            >
              Skip
            </button>
          </div>
        </div>

        <div :if={@step == :review}>
          <h1 class="text-2xl font-bold mb-2">Review Your Facts</h1>
          <p class="text-sm opacity-70 mb-6">
            These facts will be used to generate your resumes. Remove any that don't look right.
          </p>

          <div :if={@pending_facts == []} class="text-sm opacity-50 mb-6">
            No facts extracted yet. You can always add more later from the recording page.
          </div>

          <ul :if={@pending_facts != []} class="space-y-2 mb-6">
            <li
              :for={{fact, index} <- Enum.with_index(@pending_facts)}
              class="card bg-base-200 p-3 flex flex-row items-center gap-3"
            >
              <span class="flex-1 text-sm">{fact}</span>
              <button
                phx-click="remove_fact"
                phx-value-index={index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-4" />
              </button>
            </li>
          </ul>

          <button phx-click="complete_onboarding" class="btn btn-primary">
            Save & Continue <.icon name="hero-check-micro" class="size-4" />
          </button>
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

  # Profile events

  @impl true
  def handle_event("validate_profile", %{"profile" => params}, socket) do
    {:noreply, assign(socket, profile_form: to_form(params, as: "profile"))}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_profile(user, params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(profile_data: params, step: :current_role)
         |> clear_step_recordings()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(profile_form: to_form(params, as: "profile"))
         |> put_flash(:error, "Please fill in your name.")}
    end
  end

  # Recording events

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
  def handle_event("audio_data", %{"data" => data, "size" => size, "type" => type}, socket) do
    recording = %{
      id: length(socket.assigns.recordings) + 1,
      data: data,
      size: size,
      type: type,
      status: :transcribing,
      transcript: nil,
      timestamp: DateTime.utc_now()
    }

    audio_binary = Base.decode64!(data)

    task =
      Task.async(fn ->
        Resume.Transcription.transcribe(audio_binary, content_type: type)
      end)

    socket =
      socket
      |> update(:recordings, &[recording | &1])
      |> update(:task_refs, &Map.put(&1, task.ref, {:transcribe, recording.id}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("recording_error", %{"reason" => reason}, socket) do
    socket =
      socket
      |> assign(:recording, false)
      |> put_flash(:error, "Recording failed: #{reason}")

    {:noreply, socket}
  end

  # Step navigation events

  @impl true
  def handle_event("next_step", _params, socket) do
    transcripts =
      socket.assigns.recordings
      |> Enum.filter(&(&1.status == :done))
      |> Enum.map(& &1.transcript)
      |> Enum.reject(&is_nil/1)

    if transcripts == [] do
      {:noreply, advance_step(socket)}
    else
      step = socket.assigns.step

      task =
        Task.async(fn ->
          Resume.Facts.extract(transcripts, step_context(step))
        end)

      socket =
        socket
        |> assign(:extracting, true)
        |> update(:task_refs, &Map.put(&1, task.ref, {:extract, step}))

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("skip_step", _params, socket) do
    {:noreply, advance_step(socket)}
  end

  # Review events

  @impl true
  def handle_event("remove_fact", %{"index" => index}, socket) do
    index = String.to_integer(index)
    facts = List.delete_at(socket.assigns.pending_facts, index)
    {:noreply, assign(socket, pending_facts: facts)}
  end

  @impl true
  def handle_event("complete_onboarding", _params, socket) do
    user = socket.assigns.user
    profile_data = socket.assigns.profile_data
    facts = socket.assigns.pending_facts

    case Accounts.complete_onboarding(user, profile_data, facts) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome! Your profile is set up.")
         |> redirect(to: ~p"/")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  # Task results

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {{:transcribe, recording_id}, {:ok, transcript}} ->
        recordings =
          Enum.map(socket.assigns.recordings, fn
            %{id: ^recording_id} = rec -> %{rec | status: :done, transcript: transcript}
            rec -> rec
          end)

        {:noreply, assign(socket, recordings: recordings)}

      {{:transcribe, recording_id}, {:error, _reason}} ->
        recordings =
          Enum.map(socket.assigns.recordings, fn
            %{id: ^recording_id} = rec -> %{rec | status: :error}
            rec -> rec
          end)

        {:noreply, assign(socket, recordings: recordings)}

      {{:extract, _step}, {:ok, facts}} ->
        socket =
          socket
          |> assign(:extracting, false)
          |> update(:pending_facts, &(&1 ++ facts))
          |> advance_step()

        {:noreply, socket}

      {{:extract, _step}, {:error, _reason}} ->
        socket =
          socket
          |> assign(:extracting, false)
          |> put_flash(:error, "Failed to extract facts. Your recordings are still saved.")
          |> advance_step()

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  # Steps indicator component

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

  defp step_label(:profile), do: "Profile"
  defp step_label(:current_role), do: "Current Role"
  defp step_label(:previous_roles), do: "Previous"
  defp step_label(:education), do: "Education"
  defp step_label(:skills), do: "Skills"
  defp step_label(:review), do: "Review"

  defp step_config(step), do: Map.fetch!(@step_config, step)

  defp advance_step(socket) do
    current = socket.assigns.step
    current_idx = Enum.find_index(@steps, &(&1 == current))
    next = Enum.at(@steps, current_idx + 1, :review)

    socket
    |> assign(step: next)
    |> clear_step_recordings()
  end

  defp clear_step_recordings(socket) do
    assign(socket, recording: false, recordings: [], extracting: false)
  end

  defp any_transcribing?(recordings) do
    Enum.any?(recordings, &(&1.status == :transcribing))
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp format_timestamp(dt), do: Calendar.strftime(dt, "%H:%M:%S")

  defp step_context(:current_role), do: "their current or most recent role"
  defp step_context(:previous_roles), do: "their previous work experience"
  defp step_context(:education), do: "their education background"
  defp step_context(:skills), do: "their skills, certifications, and other qualifications"
  defp step_context(_), do: "their career background"
end
