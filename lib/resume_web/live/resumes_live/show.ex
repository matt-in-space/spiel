defmodule ResumeWeb.ResumesLive.Show do
  use ResumeWeb, :live_view

  require Logger

  alias Resume.{Accounts, JobPostings, Resumes}
  alias ResumeWeb.ResumeTemplates.Default
  alias ResumeWeb.ResumesLive.EditPanel

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
       editing: false,
       data_form: build_data_form(resume),
       data_params: nil,
       fetching_url: false,
       regenerating: false,
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
            <.link navigate={~p"/resumes"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left-micro" class="size-4" /> Back
            </.link>
            <.link href={~p"/resumes/#{@resume}/pdf"} class="btn btn-sm">
              <.icon name="hero-arrow-down-tray-micro" class="size-4" /> Download PDF
            </.link>
            <button
              :if={@resume.data && !@editing}
              phx-click="toggle_edit"
              class="btn btn-sm"
            >
              <.icon name="hero-pencil-square-micro" class="size-4" /> Edit
            </button>
            <button
              :if={@editing}
              type="submit"
              form="data-edit-form"
              class="btn btn-sm btn-primary"
            >
              <.icon name="hero-check-micro" class="size-4" /> Save
            </button>
            <button
              :if={@editing}
              type="button"
              phx-click="toggle_edit"
              class="btn btn-ghost btn-sm"
            >
              Cancel
            </button>
            <button
              phx-click="regenerate"
              disabled={@regenerating}
              class="btn btn-sm"
            >
              <span :if={@regenerating} class="loading loading-spinner loading-xs"></span>
              <.icon :if={!@regenerating} name="hero-arrow-path-micro" class="size-4" /> Regenerate
            </button>
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
                      label="Job Posting URL"
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
                  label="Job Posting Text"
                  type="textarea"
                  placeholder="Paste the job description here, or fetch from URL above..."
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

        <div :if={@editing && @resume.data} id="edit-panel-wrapper" phx-hook=".DetailsState">
          <.form
            for={@data_form}
            id="data-edit-form"
            phx-change="validate_data"
            phx-submit="save_data"
          >
            <EditPanel.edit_panel data_form={@data_form} />
          </.form>
        </div>

        <div
          :if={@resume.data}
          class="mx-auto max-w-[8.5in] bg-white shadow-lg rounded-sm p-[0.85in] print:shadow-none print:p-0"
        >
          {raw("<style>" <> @template_css <> "</style>")}
          {raw(render_template(@template_mod, @resume.data))}
        </div>
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".DetailsState">
      export default {
        beforeUpdate() {
          this._openStates = {};
          this.el.querySelectorAll('details[id]').forEach(d => {
            this._openStates[d.id] = d.open;
          });
        },
        updated() {
          for (const [id, open] of Object.entries(this._openStates || {})) {
            const el = document.getElementById(id);
            if (el) el.open = open;
          }
        }
      }
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
  def handle_event("toggle_edit", _params, socket) do
    editing = !socket.assigns.editing
    # Rebuild form from current resume data when entering edit mode
    socket =
      if editing do
        assign(socket,
          editing: true,
          data_form: build_data_form(socket.assigns.resume),
          data_params: nil
        )
      else
        assign(socket, editing: false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_data", %{"data" => params}, socket) do
    {:noreply, assign(socket, data_params: params)}
  end

  @impl true
  def handle_event("save_data", %{"data" => params}, socket) do
    params = process_data_params(params)

    case Resumes.update_resume_data(socket.assigns.resume, params) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> assign(
           resume: resume,
           data_form: build_data_form(resume),
           data_params: nil,
           editing: false
         )
         |> put_flash(:info, "Resume data saved.")}

      {:error, resume_changeset} ->
        Logger.warning("Resume data save failed: #{inspect(resume_changeset.errors)}")

        case resume_changeset.changes[:data] do
          %Ecto.Changeset{} = data_changeset ->
            {:noreply,
             socket
             |> assign(
               data_form: to_form(%{data_changeset | action: :validate}, as: "data"),
               data_params: nil
             )
             |> put_flash(:error, "Please fix the errors highlighted below.")}

          _ ->
            {:noreply, put_flash(socket, :error, "Failed to save.")}
        end
    end
  end

  @impl true
  def handle_event("add_item", %{"section" => section}, socket) do
    section_atom = String.to_existing_atom(section)
    changeset = changeset_from_params(socket)
    current = Ecto.Changeset.get_field(changeset, section_atom) || []
    updated = current ++ [%{}]

    new_changeset = Ecto.Changeset.put_embed(changeset, section_atom, updated)

    {:noreply, assign(socket, data_form: to_form(new_changeset, as: "data"), data_params: nil)}
  end

  @impl true
  def handle_event("remove_item", %{"section" => section, "index" => index}, socket) do
    index = String.to_integer(index)
    section_atom = String.to_existing_atom(section)
    changeset = changeset_from_params(socket)
    current = Ecto.Changeset.get_field(changeset, section_atom) || []
    updated = List.delete_at(current, index)

    new_changeset = Ecto.Changeset.put_embed(changeset, section_atom, updated)

    {:noreply, assign(socket, data_form: to_form(new_changeset, as: "data"), data_params: nil)}
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

  @impl true
  def handle_event("regenerate", _params, socket) do
    user = Accounts.get_user!(socket.assigns.user.id)
    resume = socket.assigns.resume

    task = Task.async(fn -> Resumes.regenerate_resume(resume, user) end)

    {:noreply,
     socket
     |> assign(regenerating: true)
     |> update(:task_refs, &Map.put(&1, task.ref, :regenerate))}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Resumes.delete_resume(socket.assigns.resume)

    {:noreply,
     socket
     |> put_flash(:info, "Resume deleted.")
     |> push_navigate(to: ~p"/resumes")}
  end

  @impl true
  def handle_info({ref, result}, socket) do
    Process.demonitor(ref, [:flush])
    {tag, task_refs} = Map.pop(socket.assigns.task_refs, ref)
    socket = assign(socket, task_refs: task_refs)

    case {tag, result} do
      {:regenerate, {:ok, resume}} ->
        {:noreply,
         socket
         |> assign(resume: resume, regenerating: false)
         |> put_flash(:info, "Resume regenerated.")}

      {:regenerate, {:error, _reason}} ->
        {:noreply,
         socket
         |> assign(regenerating: false)
         |> put_flash(:error, "Failed to regenerate resume. Please try again.")}

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

  defp build_data_form(resume) do
    changeset = Resumes.change_resume_data(resume)
    to_form(changeset, as: "data")
  end

  defp changeset_from_params(socket) do
    case socket.assigns.data_params do
      nil ->
        socket.assigns.data_form.source

      params ->
        params = process_data_params(params)
        Resumes.change_resume_data(socket.assigns.resume, params)
    end
  end

  defp process_data_params(params) do
    params
    |> process_array_fields("work_experience", "accomplishments")
    |> process_array_fields("skills", "skills")
    |> process_array_fields("projects", "highlights")
    |> strip_empty_dates("work_experience", ["start_date", "end_date"])
    |> strip_empty_dates("education", ["start_date", "end_date"])
    |> strip_empty_dates("certifications", ["date"])
    |> strip_empty_dates("publications", ["date"])
    |> strip_empty_dates("volunteer_work", ["start_date", "end_date"])
    |> strip_empty_dates("awards", ["date"])
  end

  defp process_array_fields(params, section, field) do
    case Map.get(params, section) do
      nil ->
        params

      items when is_map(items) ->
        updated =
          Enum.into(items, %{}, fn {idx, item} ->
            {idx, process_textarea_to_list(item, field)}
          end)

        Map.put(params, section, updated)
    end
  end

  defp process_textarea_to_list(item, field) do
    case Map.get(item, field) do
      nil ->
        item

      value when is_binary(value) ->
        list =
          value
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Map.put(item, field, list)

      _ ->
        item
    end
  end

  defp strip_empty_dates(params, section, date_fields) do
    case Map.get(params, section) do
      nil ->
        params

      items when is_map(items) ->
        updated =
          Enum.into(items, %{}, fn {idx, item} ->
            {idx, strip_empty_date_fields(item, date_fields)}
          end)

        Map.put(params, section, updated)
    end
  end

  defp strip_empty_date_fields(item, date_fields) do
    Enum.reduce(date_fields, item, fn field, acc ->
      case Map.get(acc, field) do
        %{"year" => y, "month" => m} when y in ["", nil] and m in ["", nil] ->
          Map.delete(acc, field)

        %{"year" => y} when y in ["", nil] ->
          Map.delete(acc, field)

        _ ->
          acc
      end
    end)
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
end
