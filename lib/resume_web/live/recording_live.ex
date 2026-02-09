defmodule ResumeWeb.RecordingLive do
  use ResumeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, recording: false, recordings: [], task_refs: %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <h1 class="text-2xl font-bold">Record Audio</h1>

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
      |> update(:task_refs, &Map.put(&1, task.ref, recording.id))

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
  def handle_info({ref, {:ok, transcript}}, socket) do
    Process.demonitor(ref, [:flush])
    {recording_id, task_refs} = Map.pop(socket.assigns.task_refs, ref)

    recordings =
      Enum.map(socket.assigns.recordings, fn
        %{id: ^recording_id} = rec -> %{rec | status: :done, transcript: transcript}
        rec -> rec
      end)

    {:noreply, assign(socket, recordings: recordings, task_refs: task_refs)}
  end

  @impl true
  def handle_info({ref, {:error, _reason}}, socket) do
    Process.demonitor(ref, [:flush])
    {recording_id, task_refs} = Map.pop(socket.assigns.task_refs, ref)

    recordings =
      Enum.map(socket.assigns.recordings, fn
        %{id: ^recording_id} = rec -> %{rec | status: :error}
        rec -> rec
      end)

    {:noreply, assign(socket, recordings: recordings, task_refs: task_refs)}
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
