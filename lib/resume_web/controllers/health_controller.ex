defmodule ResumeWeb.HealthController do
  use ResumeWeb, :controller

  def index(conn, _params) do
    case Ecto.Adapters.SQL.query(Resume.Repo, "SELECT 1") do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "ok"}))

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(503, Jason.encode!(%{status: "error", reason: inspect(reason)}))
    end
  end
end
