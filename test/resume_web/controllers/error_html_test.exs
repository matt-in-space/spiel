defmodule ResumeWeb.ErrorHTMLTest do
  use ResumeWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    result = render_to_string(ResumeWeb.ErrorHTML, "404", "html", [])
    assert result =~ "Page not found"
  end

  test "renders 500.html" do
    result = render_to_string(ResumeWeb.ErrorHTML, "500", "html", [])
    assert result =~ "Something went wrong"
  end
end
