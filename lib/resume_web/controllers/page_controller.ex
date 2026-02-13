defmodule ResumeWeb.PageController do
  use ResumeWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/home")
    else
      conn
      |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
      |> render(:home)
    end
  end
end
