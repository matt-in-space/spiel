defmodule ResumeWeb.PageControllerTest do
  use ResumeWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Spiel"
  end
end
