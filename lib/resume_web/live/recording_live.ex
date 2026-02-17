defmodule ResumeWeb.RecordingLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Retry}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)

    {:ok,
     assign(socket,
       user: user,
       recording: false,
       recordings: [],
       task_refs: %{},
       phase: :recording,
       pending_operations: []
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
        <div :if={@phase == :recording}>
          <div class="space-y-6">
            <h1 class="text-2xl font-semibold tracking-tight">Record Audio</h1>
            <p class="text-sm opacity-70">
              Just talk naturally about your career — jobs you've held, projects you worked on,
              skills you've picked up, accomplishments you're proud of. Stream of consciousness
              is fine; the AI will pull out the important details. Record as many clips as you like.
            </p>

            <div
              id="audio-recorder"
              phx-hook=".AudioRecorder"
              phx-update="ignore"
              data-recording={to_string(@recording)}
            >
            </div>

            <div class="flex items-center gap-4">
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

            <div :if={@recordings != []} class="space-y-3">
              <h2 class="text-lg font-semibold">Recordings</h2>
              <ul class="space-y-2">
                <li
                  :for={rec <- @recordings}
                  class="card bg-base-200 border border-base-300 p-4 flex flex-col gap-2"
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

              <div class="flex items-center gap-3 pt-2">
                <button
                  :if={has_done_recording?(@recordings)}
                  phx-click="extract_facts"
                  disabled={any_transcribing?(@recordings)}
                  class="btn btn-primary"
                >
                  Extract Details <.icon name="hero-sparkles-micro" class="size-4" />
                </button>
                <button phx-click="start_over" class="btn btn-ghost">
                  Start Over
                </button>
              </div>
            </div>
          </div>
        </div>

        <div :if={@phase == :extracting} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Extracting details from your recordings...</p>
        </div>

        <div :if={@phase == :review}>
          <h2 class="text-lg font-semibold mb-2">Review Extracted Details</h2>
          <p class="text-sm opacity-70 mb-4">
            Remove any facts that don't look right, then save.
          </p>

          <div :if={@pending_operations == []} class="text-sm opacity-50 mb-6">
            No details were extracted. Try again with different recordings.
          </div>

          <ul :if={@pending_operations != []} class="space-y-2 mb-6">
            <li
              :for={{op, index} <- Enum.with_index(@pending_operations)}
              class="card bg-base-200 border border-base-300 p-3 flex flex-row items-center gap-3"
            >
              <span
                :if={op["type"] == "update"}
                class="badge badge-warning badge-sm shrink-0"
              >
                Updating #{op["index"]}
              </span>
              <span :if={op["type"] == "add"} class="badge badge-success badge-sm shrink-0">
                New
              </span>
              <span class="flex-1 text-sm">{op["text"]}</span>
              <button
                phx-click="remove_operation"
                phx-value-index={index}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-x-mark-micro" class="size-4" />
              </button>
            </li>
          </ul>

          <div class="flex items-center gap-3">
            <button
              :if={@pending_operations != []}
              phx-click="save_facts"
              class="btn btn-primary"
            >
              Save {length(@pending_operations)} Changes
              <.icon name="hero-check-micro" class="size-4" />
            </button>
            <button phx-click="start_over" class="btn btn-ghost">
              Start Over
            </button>
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
                // Strip the data URL prefix to get raw base64
                const base64 = reader.result.split(",")[1];
                this.pushEvent("audio_data", {
                  data: base64,
                  size: blob.size,
                  type: blob.type,
                });
              };
              reader.readAsDataURL(blob);

              // Stop all tracks to release the microphone
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

  defp has_done_recording?(recordings) do
    Enum.any?(recordings, &(&1.status == :done))
  end

  defp any_transcribing?(recordings) do
    Enum.any?(recordings, &(&1.status == :transcribing))
  end

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
        Retry.with_retry(fn ->
          Resume.Transcription.transcribe(audio_binary, content_type: type)
        end)
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

  @impl true
  def handle_event("extract_facts", _params, socket) do
    transcripts =
      socket.assigns.recordings
      |> Enum.filter(&(&1.status == :done))
      |> Enum.map(& &1.transcript)

    task =
      Task.async(fn ->
        Retry.with_retry(fn ->
          Resume.Facts.extract(transcripts, "voice recordings about their career",
            existing_facts: socket.assigns.user.facts,
            user_id: socket.assigns.user.id
          )
        end)
      end)

    socket =
      socket
      |> assign(phase: :extracting)
      |> update(:task_refs, &Map.put(&1, task.ref, :extract))

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_operation", %{"index" => index}, socket) do
    index = String.to_integer(index)
    ops = List.delete_at(socket.assigns.pending_operations, index)
    {:noreply, assign(socket, pending_operations: ops)}
  end

  @impl true
  def handle_event("save_facts", _params, socket) do
    user = socket.assigns.user
    operations = socket.assigns.pending_operations
    existing_facts = user.facts || []

    {updated_facts, _descriptions} = Resume.Facts.apply_changes(existing_facts, operations)

    case Accounts.update_user_facts(user, updated_facts) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved #{length(operations)} changes!")
         |> redirect(to: ~p"/")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  @impl true
  def handle_event("start_over", _params, socket) do
    {:noreply,
     assign(socket,
       phase: :recording,
       recording: false,
       recordings: [],
       pending_operations: [],
       task_refs: %{}
     )}
  end

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

      {:extract, {:ok, operations}} ->
        {:noreply, assign(socket, phase: :review, pending_operations: operations)}

      {:extract, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(phase: :recording)
         |> put_flash(:error, "Failed to extract facts. Please try again.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp format_timestamp(dt) do
    Calendar.strftime(dt, "%H:%M:%S")
  end
end
