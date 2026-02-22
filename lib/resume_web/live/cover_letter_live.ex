defmodule ResumeWeb.CoverLetterLive do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, Billing, CoverLetters, Resumes, Retry}
  alias ResumeWeb.CoverLetterTemplates

  @generating_messages [
    "Reviewing your experience...",
    "Crafting your opening paragraph...",
    "Highlighting your key qualifications...",
    "Tailoring to the position...",
    "Polishing the final draft..."
  ]

  @feedback_placeholders [
    "Make the opening more enthusiastic about the role",
    "Emphasize my management experience more",
    "Shorten the body paragraphs to be more concise",
    "Add more specific examples from my work experience",
    "Make the tone more conversational and less stiff",
    "Focus more on my technical skills in the body",
    "Strengthen the closing paragraph with a clear call to action",
    "Tone down the formality a bit"
  ]

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    resume = Resumes.get_user_resume!(user.id, id)
    paid = Billing.paid_feature?(user)
    cover_letter = CoverLetters.get_by_resume(resume.id)
    template_key = (cover_letter && cover_letter.template) || "formal"
    template_mod = CoverLetterTemplates.get(template_key)

    socket =
      assign(socket,
        user: user,
        resume: resume,
        paid: paid,
        cover_letter: cover_letter,
        template_mod: template_mod,
        template_css: template_mod.css(),
        template_options: CoverLetterTemplates.template_options(),
        feedback_form: to_form(%{"message" => ""}, as: "feedback"),
        preview_content: nil,
        preview_explanation: nil,
        processing_feedback: false,
        recording: false,
        transcribing: false,
        editing_section: nil,
        section_form: nil,
        sidebar_open: false,
        feedback_placeholder: Enum.random(@feedback_placeholders),
        generating: false,
        generating_messages: @generating_messages,
        generating_message_index: 0,
        task_refs: %{}
      )

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

  @impl true
  def render(assigns) do
    current_data = cover_letter_data(assigns.cover_letter)

    assigns = assign(assigns, :current_data, current_data)

    ~H"""
    <Layouts.app
      flash={@flash}
      breadcrumbs={[%{label: @resume.title, to: ~p"/resumes/#{@resume}"}, %{label: "Cover Letter"}]}
    >
      <div class="drawer drawer-end">
        <input
          id="sidebar-toggle"
          type="checkbox"
          class="drawer-toggle"
          checked={@sidebar_open}
          phx-click="toggle_sidebar"
        />
        <div class="drawer-content space-y-6">
          <div class="flex items-center justify-between">
            <div role="tablist" class="tabs tabs-box tabs-sm">
              <.link navigate={~p"/resumes/#{@resume}"} role="tab" class="tab">
                Resume
              </.link>
              <span role="tab" class="tab tab-active">Cover Letter</span>
            </div>
            <.link
              :if={@cover_letter}
              href={~p"/resumes/#{@resume}/cover-letter/pdf"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-arrow-down-tray-micro" class="size-4" /> Download PDF
            </.link>
          </div>

          <%= if !@paid do %>
            <div class="flex flex-col items-center justify-center py-24 gap-4">
              <.icon name="hero-lock-closed" class="size-12 text-base-content/30" />
              <h2 class="text-xl font-semibold">Cover Letters are a paid feature</h2>
              <p class="text-base-content/60 text-center max-w-md">
                Generate tailored cover letters that complement your resume. Get unlimited access to create and refine cover letters for every application.
              </p>
              <.link navigate={~p"/billing"} class="btn btn-primary">
                Get Unlimited Access
              </.link>
            </div>
          <% else %>
            <label
              :if={!@generating}
              for="sidebar-toggle"
              class="fixed right-0 top-1/2 -translate-y-1/2 z-10 bg-base-200 hover:bg-base-300 transition-colors rounded-l-lg px-2.5 py-5 cursor-pointer shadow-md"
            >
              <.icon name="hero-chevron-left-micro" class="size-5" />
            </label>

            <div
              :if={!@cover_letter && !@generating}
              class="flex flex-col items-center justify-center py-24 gap-4"
            >
              <.icon name="hero-document-text" class="size-12 text-base-content/30" />
              <h2 class="text-xl font-semibold">No cover letter yet</h2>
              <p class="text-base-content/60 text-center max-w-md">
                Generate a cover letter tailored to this position based on your resume and profile.
              </p>
              <button phx-click="generate" class="btn btn-primary">
                <.icon name="hero-sparkles-solid" class="size-4" /> Generate Cover Letter
              </button>
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
                <span class="loading loading-spinner loading-sm"></span> Updating cover letter...
              </div>

              <div :if={!@processing_feedback && @preview_content} class="space-y-3">
                <div :if={@preview_explanation} class="bg-base-200 rounded-lg p-3 text-sm">
                  <p class="font-medium mb-1">What changed</p>
                  <p class="text-base-content/70">{@preview_explanation}</p>
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

              <div :if={!@processing_feedback && !@preview_content}>
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
              id="cover-letter-scale-wrapper"
              phx-hook=".CoverLetterScale"
              class="overflow-hidden"
            >
              <div
                id="cover-letter-scale-inner"
                phx-hook=".CoverLetterSectionEditor"
                class="w-[8.5in] bg-white border border-base-300 rounded-sm print:border-none print:p-0 origin-top-left p-[1in]"
              >
                <div
                  :if={@preview_content}
                  class="flex items-center gap-2 mb-4 -mt-4 -mx-4 px-4 py-2 bg-warning/10 border-b border-warning/30"
                >
                  <.icon name="hero-eye-micro" class="size-4 text-warning" />
                  <span class="text-sm font-medium text-warning">Preview — unsaved changes</span>
                </div>
                {raw("<style>" <> @template_css <> section_editor_css() <> "</style>")}
                {raw(render_template(@template_mod, display_data(@preview_content, @current_data)))}
              </div>
            </div>
          <% end %>
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

            <div :if={@cover_letter} class="space-y-2">
              <h3 class="text-sm font-medium">Template</h3>
              <div class="grid grid-cols-2 gap-3">
                <button
                  :for={{name, key} <- @template_options}
                  phx-click="change_template"
                  phx-value-template={key}
                  class={[
                    "rounded-lg overflow-hidden border-2 transition-colors cursor-pointer p-3 text-center",
                    if(key == (@cover_letter && @cover_letter.template),
                      do: "border-primary bg-primary/5",
                      else: "border-base-300 hover:border-base-content/30"
                    )
                  ]}
                >
                  <div class="text-sm font-medium">{name}</div>
                </button>
              </div>
            </div>

            <div :if={@cover_letter} class="space-y-2">
              <h3 class="text-sm font-medium">Actions</h3>
              <button
                phx-click="regenerate"
                data-confirm="This will replace your current cover letter. Continue?"
                class="btn btn-sm btn-ghost w-full justify-start"
              >
                <.icon name="hero-arrow-path-micro" class="size-4" /> Regenerate
              </button>
              <button
                phx-click="delete_cover_letter"
                data-confirm="Delete this cover letter?"
                class="btn btn-sm btn-ghost text-error w-full justify-start"
              >
                <.icon name="hero-trash-micro" class="size-4" /> Delete Cover Letter
              </button>
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
            <.section_editor_fields section={@editing_section} form={@section_form} />
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
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CoverLetterScale">
      export default {
        mounted() {
          this.inner = this.el.querySelector("#cover-letter-scale-inner");
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CoverLetterSectionEditor">
      export default {
        mounted() {
          this.el.addEventListener("click", (e) => {
            const target = e.target.closest("[data-section]");
            if (!target) return;
            e.preventDefault();
            this.pushEvent("open_section_editor", {
              section: target.dataset.section,
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

  # Events

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("generate", _params, socket) do
    {:noreply, start_generation(socket)}
  end

  @impl true
  def handle_event("regenerate", _params, socket) do
    {:noreply, start_generation(socket)}
  end

  @impl true
  def handle_event("change_template", %{"template" => template}, socket) do
    cover_letter = socket.assigns.cover_letter

    {:ok, cover_letter} = CoverLetters.update_cover_letter(cover_letter, %{template: template})
    template_mod = CoverLetterTemplates.get(template)

    {:noreply,
     assign(socket,
       cover_letter: cover_letter,
       template_mod: template_mod,
       template_css: template_mod.css()
     )}
  end

  @impl true
  def handle_event("delete_cover_letter", _params, socket) do
    {:ok, _} = CoverLetters.delete_cover_letter(socket.assigns.cover_letter)

    {:noreply,
     socket
     |> assign(cover_letter: nil, preview_content: nil, preview_explanation: nil)
     |> put_flash(:info, "Cover letter deleted.")}
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
    preview_content = socket.assigns.preview_content
    cover_letter = socket.assigns.cover_letter

    case CoverLetters.update_cover_letter(cover_letter, %{content: preview_content}) do
      {:ok, cover_letter} ->
        {:noreply,
         socket
         |> assign(
           cover_letter: cover_letter,
           preview_content: nil,
           preview_explanation: nil
         )
         |> put_flash(:info, "Changes saved.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save changes.")}
    end
  end

  @impl true
  def handle_event("revert_changes", _params, socket) do
    {:noreply, assign(socket, preview_content: nil, preview_explanation: nil)}
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

  # Section editor events

  @impl true
  def handle_event("open_section_editor", %{"section" => section}, socket) do
    if socket.assigns.preview_content do
      {:noreply, socket}
    else
      current_data = cover_letter_data(socket.assigns.cover_letter)
      section_form = build_section_form(current_data, section)

      {:noreply,
       assign(socket,
         editing_section: section,
         section_form: section_form
       )}
    end
  end

  @impl true
  def handle_event("save_section_edit", %{"section" => params}, socket) do
    section = socket.assigns.editing_section
    cover_letter = socket.assigns.cover_letter
    content = cover_letter.content
    updated_content = apply_section_edit(content, section, params)

    case CoverLetters.update_cover_letter(cover_letter, %{content: updated_content}) do
      {:ok, cover_letter} ->
        {:noreply,
         assign(socket,
           cover_letter: cover_letter,
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

  # Async message handling

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
      {:generate, {:ok, cover_letter}} ->
        template_mod = CoverLetterTemplates.get(cover_letter.template)

        {:noreply,
         socket
         |> assign(
           generating: false,
           cover_letter: cover_letter,
           template_mod: template_mod,
           template_css: template_mod.css()
         )
         |> put_flash(:info, "Your cover letter is ready!")}

      {:generate, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(generating: false)
         |> put_flash(:error, "Failed to generate cover letter. Please try again.")}

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

  # Private helpers

  defp start_generation(socket) do
    resume = socket.assigns.resume
    user = socket.assigns.user

    task =
      Task.async(fn ->
        Retry.with_retry(fn -> CoverLetters.generate_cover_letter(resume, user) end)
      end)

    Process.send_after(self(), :rotate_generating_message, 3_000)

    socket
    |> assign(generating: true, generating_message_index: 0)
    |> update(:task_refs, &Map.put(&1, task.ref, :generate))
  end

  defp cover_letter_data(nil), do: nil

  defp cover_letter_data(%{content: nil}), do: nil

  defp cover_letter_data(cover_letter) do
    CoverLetters.dump_content(cover_letter)
  end

  defp process_feedback_message(socket, message) do
    user = Accounts.get_user!(socket.assigns.user.id)
    cover_letter = socket.assigns.cover_letter
    current_content = socket.assigns.preview_content || cover_letter.content

    task =
      Task.async(fn ->
        Retry.with_retry(fn ->
          CoverLetters.Feedback.process_feedback(current_content, user, message, history: [])
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
    current_content =
      socket.assigns.preview_content || socket.assigns.cover_letter.content

    if result.content == current_content do
      socket
      |> assign(processing_feedback: false)
      |> put_flash(:info, "No changes to apply. Try being more specific about what to change.")
    else
      assign(socket,
        processing_feedback: false,
        preview_content: result.content,
        preview_explanation: result.explanation
      )
    end
  end

  defp render_template(template_mod, data) do
    template_mod.render(%{data: data})
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp display_data(nil, current_data), do: current_data

  defp display_data(preview_content, _current_data) do
    %CoverLetters.CoverLetterData{}
    |> CoverLetters.CoverLetterData.changeset(preview_content)
    |> Ecto.Changeset.apply_changes()
  end

  defp section_editor_css do
    """
    [data-section] { cursor: pointer; transition: outline 0.15s; border-radius: 2px; }
    [data-section].section-editable-hover { outline: 2px solid oklch(0.65 0.2 250 / 0.5); outline-offset: 4px; }
    """
  end

  defp section_label("greeting"), do: "Greeting"
  defp section_label("opening"), do: "Opening"
  defp section_label("body"), do: "Body"
  defp section_label("closing"), do: "Closing"
  defp section_label("signature"), do: "Signature"

  # Section editor form fields

  attr :section, :string, required: true
  attr :form, :any, required: true

  defp section_editor_fields(%{section: "greeting"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:greeting]} type="text" label="Greeting" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "opening"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:opening]} type="textarea" label="Opening paragraph" rows="4" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "body"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input
        field={@form[:body]}
        type="textarea"
        label="Body paragraphs (separate with a blank line)"
        rows="8"
      />
    </div>
    """
  end

  defp section_editor_fields(%{section: "closing"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:closing]} type="textarea" label="Closing paragraph" rows="4" />
    </div>
    """
  end

  defp section_editor_fields(%{section: "signature"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <.input field={@form[:signature]} type="textarea" label="Signature" rows="3" />
    </div>
    """
  end

  # Build forms for section editing

  defp build_section_form(data, "greeting") do
    to_form(%{"greeting" => data.greeting || ""}, as: "section")
  end

  defp build_section_form(data, "opening") do
    to_form(%{"opening" => data.opening || ""}, as: "section")
  end

  defp build_section_form(data, "body") do
    body_text = Enum.join(data.body || [], "\n\n")
    to_form(%{"body" => body_text}, as: "section")
  end

  defp build_section_form(data, "closing") do
    to_form(%{"closing" => data.closing || ""}, as: "section")
  end

  defp build_section_form(data, "signature") do
    to_form(%{"signature" => data.signature || ""}, as: "section")
  end

  # Apply section edits

  defp apply_section_edit(content, "greeting", params) do
    Map.put(content, "greeting", params["greeting"])
  end

  defp apply_section_edit(content, "opening", params) do
    Map.put(content, "opening", params["opening"])
  end

  defp apply_section_edit(content, "body", params) do
    paragraphs =
      params["body"]
      |> String.split(~r/\n\s*\n/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    Map.put(content, "body", paragraphs)
  end

  defp apply_section_edit(content, "closing", params) do
    Map.put(content, "closing", params["closing"])
  end

  defp apply_section_edit(content, "signature", params) do
    Map.put(content, "signature", params["signature"])
  end
end
