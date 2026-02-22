defmodule ResumeWeb.Admin.UsersLive do
  use ResumeWeb, :live_view

  alias Resume.Admin
  alias ResumeWeb.Layouts

  @impl true
  def mount(_params, _session, socket) do
    result = Admin.list_users()

    {:ok,
     socket
     |> assign(
       search: "",
       page: result.page,
       total_pages: result.total_pages,
       total: result.total,
       page_title: "Admin: Users"
     )
     |> stream(:users, result.users)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    search = String.trim(search)
    result = Admin.list_users(search: search, page: 1)

    {:noreply,
     socket
     |> assign(
       search: search,
       page: result.page,
       total_pages: result.total_pages,
       total: result.total
     )
     |> stream(:users, result.users, reset: true)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page = String.to_integer(page)
    result = Admin.list_users(search: socket.assigns.search, page: page)

    {:noreply,
     socket
     |> assign(
       page: result.page,
       total_pages: result.total_pages,
       total: result.total
     )
     |> stream(:users, result.users, reset: true)}
  end

  defp format_date(dt), do: Calendar.strftime(dt, "%Y-%m-%d")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} breadcrumbs={[%{label: "Admin", to: ~p"/admin"}, %{label: "Users"}]}>
      <.header>
        Admin: Users
        <:subtitle>{@total} total users</:subtitle>
      </.header>

      <form phx-submit="search" class="mb-6">
        <div class="flex gap-2">
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search by email..."
            class="input input-bordered input-sm flex-1"
            phx-debounce="300"
          />
          <button type="submit" class="btn btn-sm btn-primary">Search</button>
          <.link
            :if={@search != ""}
            patch={~p"/admin/users"}
            class="btn btn-sm btn-ghost"
            phx-click="search"
            phx-value-search=""
          >
            Clear
          </.link>
        </div>
      </form>

      <.table id="users" rows={@streams.users}>
        <:col :let={{_id, row}} label="Email">
          <.link navigate={~p"/admin/users/#{row.user.id}"} class="link link-primary">
            {row.user.email}
          </.link>
        </:col>
        <:col :let={{_id, row}} label="Role">{row.user.role}</:col>
        <:col :let={{_id, row}} label="Access">{row.user.access_level}</:col>
        <:col :let={{_id, row}} label="Resumes">{row.resume_count}</:col>
        <:col :let={{_id, row}} label="Joined">{format_date(row.user.inserted_at)}</:col>
      </.table>

      <div :if={@total_pages > 1} class="flex justify-center gap-2 mt-4">
        <button
          :for={p <- 1..@total_pages}
          phx-click="paginate"
          phx-value-page={p}
          class={["btn btn-sm", p == @page && "btn-primary", p != @page && "btn-ghost"]}
        >
          {p}
        </button>
      </div>
    </Layouts.app>
    """
  end
end
