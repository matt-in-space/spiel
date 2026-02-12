defmodule ResumeWeb.PageController do
  use ResumeWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/home")
    else
      render(conn, :home)
    end
  end
end
