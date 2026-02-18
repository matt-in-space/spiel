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

  def terms(conn, _params) do
    conn
    |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
    |> assign(:page_title, "Terms of Use")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> put_root_layout(html: {ResumeWeb.Layouts, :landing})
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end
end
