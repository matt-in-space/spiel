defmodule ResumeWeb.PageController do
  use ResumeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
