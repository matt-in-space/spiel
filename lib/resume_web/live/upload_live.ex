defmodule ResumeWeb.UploadLive do
  use ResumeWeb, :live_view

  alias Resume.{Accounts, Retry}

  @impl true
  def mount(_params, session, socket) do
    user = get_user(socket, session)

    {:ok,
     socket
     |> assign(
       user: user,
       phase: :input,
       text_form: to_form(%{"text" => ""}, as: "paste"),
       extracted_text: "",
       pending_operations: [],
       upgrade_prompt: nil,
       task_refs: %{}
     )
     |> allow_upload(:document, accept: ~w(.txt .pdf), max_entries: 1, max_file_size: 2_000_000)}
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
        <div :if={@upgrade_prompt} class="alert alert-warning mb-4">
          <.icon name="hero-lock-closed-micro" class="size-5" />
          <span>{@upgrade_prompt}</span>
          <.link navigate={~p"/billing"} class="btn btn-sm btn-primary">
            Get Unlimited Access
          </.link>
        </div>

        <h1 class="text-2xl font-semibold tracking-tight">Upload or Paste Text</h1>
        <p class="text-sm opacity-70">
          Upload a .txt or .pdf file, or paste text from your resume, LinkedIn, or other source.
        </p>

        <div :if={@phase == :input}>
          <.form for={@text_form} phx-change="validate_paste" phx-submit="submit_input">
            <div class="space-y-4">
              <div
                class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center"
                phx-drop-target={@uploads.document.ref}
              >
                <.icon name="hero-document-arrow-up" class="size-8 mx-auto opacity-50 mb-2" />
                <p class="text-sm opacity-70 mb-2">Drag & drop a .txt or .pdf file here, or</p>
                <.live_file_input
                  upload={@uploads.document}
                  class="file-input file-input-bordered file-input-sm"
                />

                <div :for={entry <- @uploads.document.entries} class="mt-3 flex items-center gap-2">
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

                <div :for={err <- upload_errors(@uploads.document)} class="text-error text-sm mt-2">
                  {upload_error_message(err)}
                </div>
              </div>

              <div class="divider">OR</div>

              <.input
                field={@text_form[:text]}
                type="textarea"
                label="Paste text"
                placeholder="Paste your resume, LinkedIn summary, or any career-related text here..."
                rows="8"
              />

              <button type="submit" class="btn btn-primary">
                Continue <.icon name="hero-arrow-right-micro" class="size-4" />
              </button>
            </div>
          </.form>
        </div>

        <div :if={@phase == :preview}>
          <h2 class="text-lg font-semibold mb-2">Preview</h2>
          <div class="bg-base-200 rounded-lg p-4 max-h-80 overflow-y-auto mb-4">
            <pre class="whitespace-pre-wrap text-sm">{@extracted_text}</pre>
          </div>
          <div class="flex items-center gap-3">
            <button phx-click="extract_facts" class="btn btn-primary">
              Extract Details <.icon name="hero-sparkles-micro" class="size-4" />
            </button>
            <button phx-click="back_to_input" class="btn btn-ghost">
              Back
            </button>
          </div>
        </div>

        <div :if={@phase == :extracting} class="flex flex-col items-center gap-3 py-12">
          <span class="loading loading-spinner loading-lg"></span>
          <p class="text-sm opacity-70">Extracting details from your text...</p>
        </div>

        <div :if={@phase == :review}>
          <h2 class="text-lg font-semibold mb-2">Review Extracted Details</h2>
          <p class="text-sm opacity-70 mb-4">
            Remove any facts that don't look right, then save.
          </p>

          <div :if={@pending_operations == []} class="text-sm opacity-50 mb-6">
            No details were extracted. Try again with different text.
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
    """
  end

  defp upload_error_message(:too_large),
    do: "File is too large (max 2 MB). Try pasting the text instead."

  defp upload_error_message(:not_accepted),
    do: "Unsupported format — please upload a .txt or .pdf file."

  defp upload_error_message(:too_many_files), do: "Only one file at a time."
  defp upload_error_message(_), do: "Upload failed. Try pasting the text directly."

  @impl true
  def handle_event("validate_paste", %{"paste" => params}, socket) do
    {:noreply, assign(socket, text_form: to_form(params, as: "paste"))}
  end

  @impl true
  def handle_event("submit_input", %{"paste" => %{"text" => pasted_text}}, socket) do
    results =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        case Resume.Documents.extract_text(path, entry.client_type) do
          {:ok, text} -> {:ok, text}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)

    extraction_error =
      Enum.find_value(results, fn
        {:error, reason} -> reason
        _ -> nil
      end)

    file_text =
      results
      |> Enum.reject(&match?({:error, _}, &1))
      |> Enum.join("\n\n")
      |> String.trim()

    pasted_text = String.trim(pasted_text)

    combined =
      [file_text, pasted_text]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    cond do
      extraction_error != nil ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Couldn't read that file. Make sure it's a valid .txt or .pdf and try again, or paste the text directly."
         )}

      combined == "" ->
        {:noreply, put_flash(socket, :error, "Please upload a file or paste some text.")}

      true ->
        {:noreply,
         socket
         |> assign(phase: :preview, extracted_text: combined)
         |> clear_flash()}
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  @impl true
  def handle_event("back_to_input", _params, socket) do
    {:noreply, assign(socket, phase: :input)}
  end

  @impl true
  def handle_event("extract_facts", _params, socket) do
    case Resume.Billing.check_allowance(socket.assigns.user, :fact_update) do
      :ok ->
        text = socket.assigns.extracted_text

        task =
          Task.async(fn ->
            Retry.with_retry(fn ->
              Resume.Facts.extract([text], "an uploaded document about their career",
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

      {:error, :limit_reached, message} ->
        {:noreply, assign(socket, upgrade_prompt: message)}
    end
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
     socket
     |> assign(
       phase: :input,
       text_form: to_form(%{"text" => ""}, as: "paste"),
       extracted_text: "",
       pending_operations: []
     )
     |> allow_upload(:document, accept: ~w(.txt .pdf), max_entries: 1, max_file_size: 2_000_000)}
  end

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:extract, {:ok, operations}} ->
        {:noreply, assign(socket, phase: :review, pending_operations: operations)}

      {:extract, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(phase: :preview)
         |> put_flash(:error, "Failed to extract facts. Please try again.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end
end
