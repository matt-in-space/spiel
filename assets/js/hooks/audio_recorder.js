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
        const blob = new Blob(this.audioChunks, {
          type: this.mediaRecorder.mimeType,
        });
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
