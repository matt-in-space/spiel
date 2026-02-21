defmodule ResumeWeb.CoachLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Facts, Interview}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = user.default_resume_data || %{}
    original_facts = user.facts || []
    original_career_goal = profile["career_goal"]

    {:ok,
     socket
     |> assign(
       user: user,
       profile: profile,
       phase: :chat,
       # Chat
       messages: [],
       turn_number: 0,
       input_form: to_form(%{"message" => ""}, as: "chat"),
       recording: false,
       transcribing: false,
       processing: false,
       # Accumulation
       original_facts: original_facts,
       working_facts: original_facts,
       pending_descriptions: [],
       pending_career_goal: nil,
       original_career_goal: original_career_goal,
       # Shared
       upgrade_prompt: nil,
       task_refs: %{},
       page_title: "Career Coach"
     )
     |> start_opening_question()}
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

  defp start_opening_question(socket) do
    case Resume.Billing.check_allowance(socket.assigns.user, :fact_update) do
      :ok ->
        task =
          Task.async(fn ->
            Interview.coach_opening_question(
              socket.assigns.original_facts,
              socket.assigns.profile,
              user_id: socket.assigns.user.id
            )
          end)

        socket
        |> assign(processing: true)
        |> update(:task_refs, &Map.put(&1, task.ref, :coach_opening))

      {:error, :limit_reached, message} ->
        assign(socket, upgrade_prompt: message)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      breadcrumbs={[%{label: "Profile", to: ~p"/profile"}, %{label: "Career Coach"}]}
    >
      <div :if={@phase == :chat} class="space-y-4 max-w-2xl mx-auto">
        <div>
          <h1 class="text-2xl font-semibold tracking-tight">Career Coach</h1>
          <p class="text-sm opacity-70">
            Let's catch up on what's new — tell me about recent changes to your career.
          </p>
        </div>

        <div :if={@upgrade_prompt} class="alert alert-warning">
          <.icon name="hero-lock-closed-micro" class="size-5" />
          <span>{@upgrade_prompt}</span>
          <.link navigate={~p"/billing"} class="btn btn-sm btn-primary">
            Get Unlimited Access
          </.link>
        </div>

        <div :if={!@upgrade_prompt} class="flex flex-col h-[55vh]">
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

            <div :if={@processing} class="chat chat-start">
              <div class="chat-bubble chat-bubble-primary">
                <span class="loading loading-dots loading-sm"></span>
              </div>
            </div>
          </div>

          <div
            id="audio-recorder"
            phx-hook="AudioRecorder"
            phx-update="ignore"
            data-recording={to_string(@recording)}
          >
          </div>

          <div :if={@transcribing} class="flex items-center gap-2 text-sm mb-2">
            <span class="loading loading-spinner loading-xs"></span> Transcribing...
          </div>

          <.form
            for={@input_form}
            phx-change="validate_chat"
            phx-submit="send_message"
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
              id={@input_form[:message].id}
              name={@input_form[:message].name}
              placeholder="Type your response..."
              autocomplete="off"
              rows="1"
              phx-hook="AutoGrow"
              class="w-full resize-none overflow-hidden border-none bg-transparent px-3 pt-3 pb-1 text-sm focus:outline-none focus:ring-0"
            >{Phoenix.HTML.Form.normalize_value("textarea", @input_form[:message].value)}</textarea>
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
                disabled={@recording || @processing || @transcribing}
              >
                <.icon name="hero-paper-airplane-solid" class="size-3.5" />
              </button>
            </div>
          </.form>

          <div class="flex items-center justify-between mt-3">
            <.link navigate={~p"/profile?tab=details_rules"} class="btn btn-ghost btn-sm">
              Discard
            </.link>
            <button phx-click="finish_chat" class="btn btn-primary btn-sm">
              I'm done <.icon name="hero-arrow-right-micro" class="size-4" />
            </button>
          </div>
        </div>
      </div>

      <div :if={@phase == :review} class="space-y-6 max-w-2xl mx-auto">
        <div>
          <h1 class="text-2xl font-semibold tracking-tight">Review Changes</h1>
          <p class="text-sm opacity-70">
            Here's what we'll update on your profile. Confirm to save.
          </p>
        </div>

        <div
          :if={@pending_career_goal && @pending_career_goal != @original_career_goal}
          class="card bg-base-200 border border-base-300 p-4 space-y-2"
        >
          <h3 class="text-sm font-semibold opacity-70">Career Goal</h3>
          <p :if={@original_career_goal} class="text-sm line-through opacity-50">
            {@original_career_goal}
          </p>
          <p class="text-sm">{@pending_career_goal}</p>
        </div>

        <div :if={@pending_descriptions != []} class="space-y-2">
          <h3 class="text-sm font-semibold opacity-70">Fact Changes</h3>
          <div :for={desc <- @pending_descriptions} class="flex items-start gap-2 text-sm">
            <.change_icon description={desc} />
            <span>{desc}</span>
          </div>
        </div>

        <div
          :if={
            @pending_descriptions == [] &&
              !(@pending_career_goal && @pending_career_goal != @original_career_goal)
          }
          class="text-sm opacity-50 text-center py-8"
        >
          No changes were detected during the conversation.
        </div>

        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <button phx-click="back_to_chat" class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left-micro" class="size-4" /> Back to Chat
            </button>
            <.link navigate={~p"/profile?tab=details_rules"} class="btn btn-ghost btn-sm">
              Discard
            </.link>
          </div>
          <button
            phx-click="confirm_changes"
            class="btn btn-primary btn-sm"
            disabled={
              @pending_descriptions == [] &&
                !(@pending_career_goal && @pending_career_goal != @original_career_goal)
            }
          >
            <.icon name="hero-check-micro" class="size-4" /> Confirm Changes
          </button>
        </div>
      </div>
    </Layouts.app>

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

  defp change_icon(%{description: desc} = assigns) do
    cond do
      String.starts_with?(desc, "Added") ->
        ~H"""
        <.icon name="hero-plus-circle" class="size-4 text-success mt-0.5 shrink-0" />
        """

      String.starts_with?(desc, "Updated") ->
        ~H"""
        <.icon name="hero-pencil" class="size-4 text-info mt-0.5 shrink-0" />
        """

      String.starts_with?(desc, "Removed") ->
        ~H"""
        <.icon name="hero-minus-circle" class="size-4 text-error mt-0.5 shrink-0" />
        """

      true ->
        ~H"""
        <.icon name="hero-arrow-path" class="size-4 opacity-50 mt-0.5 shrink-0" />
        """
    end
  end

  # Chat events

  @impl true
  def handle_event("validate_chat", %{"chat" => params}, socket) do
    {:noreply, assign(socket, input_form: to_form(params, as: "chat"))}
  end

  @impl true
  def handle_event("send_message", %{"chat" => %{"message" => message}}, socket) do
    message = String.trim(message)

    if message == "" do
      {:noreply, socket}
    else
      case Resume.Billing.check_allowance(socket.assigns.user, :fact_update) do
        :ok ->
          {:noreply, process_user_message(socket, message)}

        {:error, :limit_reached, message} ->
          {:noreply, assign(socket, upgrade_prompt: message)}
      end
    end
  end

  # Audio events

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
    user_id = socket.assigns.user.id

    task =
      Task.async(fn ->
        Resume.Transcription.tracked_transcribe(audio_binary, [content_type: type], %{
          user_id: user_id,
          caller: "transcription"
        })
      end)

    {:noreply,
     socket
     |> assign(recording: false, transcribing: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :transcribe))}
  end

  @impl true
  def handle_event("recording_error", %{"reason" => reason}, socket) do
    {:noreply,
     socket
     |> assign(recording: false)
     |> put_flash(:error, "Recording failed: #{reason}")}
  end

  # Phase transitions

  @impl true
  def handle_event("finish_chat", _params, socket) do
    {:noreply, assign(socket, phase: :review)}
  end

  @impl true
  def handle_event("back_to_chat", _params, socket) do
    {:noreply, assign(socket, phase: :chat)}
  end

  # Confirm

  @impl true
  def handle_event("confirm_changes", _params, socket) do
    user = socket.assigns.user
    working_facts = socket.assigns.working_facts
    pending_goal = socket.assigns.pending_career_goal
    original_goal = socket.assigns.original_career_goal
    descriptions = socket.assigns.pending_descriptions

    {:ok, user} = Accounts.update_user_facts(user, working_facts)

    user =
      if pending_goal && pending_goal != original_goal do
        {:ok, user} = Accounts.update_user_career_goal(user, pending_goal)
        user
      else
        user
      end

    change_count = length(descriptions)

    goal_changed? = pending_goal && pending_goal != original_goal

    flash_msg =
      cond do
        change_count > 0 && goal_changed? ->
          "Saved #{change_count} fact #{pluralize(change_count, "change", "changes")} and updated career goal."

        change_count > 0 ->
          "Saved #{change_count} fact #{pluralize(change_count, "change", "changes")}."

        goal_changed? ->
          "Updated career goal."

        true ->
          "No changes to save."
      end

    {:noreply,
     socket
     |> assign(user: user)
     |> put_flash(:info, flash_msg)
     |> redirect(to: ~p"/profile?tab=details_rules")}
  end

  defp pluralize(1, singular, _plural), do: singular
  defp pluralize(_, _singular, plural), do: plural

  # Task results

  @impl true
  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:coach_opening, {:ok, question}} ->
        {:noreply,
         socket
         |> assign(
           messages: [%{role: :assistant, content: question}],
           processing: false
         )}

      {:coach_opening, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(
           messages: [
             %{
               role: :assistant,
               content:
                 "What's been happening in your career lately? Any new roles, projects, or skills to add?"
             }
           ],
           processing: false
         )}

      {:coach_turn,
       {:ok, %{fact_operations: operations, question: question, should_wrap_up: wrap} = turn}} ->
        {updated_facts, new_descriptions} =
          Facts.apply_changes(socket.assigns.working_facts, operations)

        socket =
          socket
          |> assign(working_facts: updated_facts)
          |> update(:pending_descriptions, &(&1 ++ new_descriptions))
          |> then(fn s ->
            if turn[:career_goal], do: assign(s, :pending_career_goal, turn.career_goal), else: s
          end)
          |> assign(
            messages: socket.assigns.messages ++ [%{role: :assistant, content: question}],
            processing: false
          )

        if wrap do
          {:noreply, assign(socket, phase: :review)}
        else
          {:noreply, socket}
        end

      {:coach_turn, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(processing: false)
         |> put_flash(:error, "Something went wrong. Please try again.")}

      {:transcribe, {:ok, transcript}} ->
        {:noreply,
         socket
         |> assign(transcribing: false)
         |> process_user_message(transcript)}

      {:transcribe, {:error, _reason}} ->
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

  defp process_user_message(socket, message) do
    turn = socket.assigns.turn_number + 1
    messages = socket.assigns.messages ++ [%{role: :user, content: message}]
    profile = socket.assigns.profile

    history =
      Enum.map(messages, fn msg ->
        %{role: msg.role, content: msg.content}
      end)

    task =
      Task.async(fn ->
        Interview.process_turn(
          message,
          history,
          socket.assigns.working_facts,
          turn,
          profile,
          user_id: socket.assigns.user.id
        )
      end)

    socket
    |> assign(
      messages: messages,
      turn_number: turn,
      processing: true,
      input_form: to_form(%{"message" => ""}, as: "chat")
    )
    |> update(:task_refs, &Map.put(&1, task.ref, :coach_turn))
  end
end
