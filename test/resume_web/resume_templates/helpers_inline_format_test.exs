defmodule ResumeWeb.ResumeTemplates.HelpersInlineFormatTest do
  use ExUnit.Case, async: true

  import ResumeWeb.ResumeTemplates.Helpers, only: [inline_format: 1]

  defp render(text), do: text |> inline_format() |> Phoenix.HTML.safe_to_string()

  test "plain text passes through unchanged" do
    assert render("Shipped v2.0 to 10k users") == "Shipped v2.0 to 10k users"
  end

  test "nil renders as empty" do
    assert render(nil) == ""
  end

  test "bold, italic and highlight" do
    assert render("Built with **React** and **Ruby on Rails**") ==
             "Built with <strong>React</strong> and <strong>Ruby on Rails</strong>"

    assert render("An *open source* tool") == "An <em>open source</em> tool"
    assert render("Cut costs by ==40%==") == "Cut costs by <mark>40%</mark>"
  end

  test "markers can nest inside bold" do
    assert render("**fast *and* ==cheap==**") ==
             "<strong>fast <em>and</em> <mark>cheap</mark></strong>"
  end

  test "raw HTML is escaped, not interpreted" do
    assert render("<b>React</b> & <script>alert(1)</script>") ==
             "&lt;b&gt;React&lt;/b&gt; &amp; &lt;script&gt;alert(1)&lt;/script&gt;"
  end

  test "markers wrapping HTML-ish text stay escaped" do
    assert render("**<img src=x>**") == "<strong>&lt;img src=x&gt;</strong>"
  end

  test "stray or spaced asterisks are left alone" do
    assert render("Rated 5* by users") == "Rated 5* by users"
    assert render("a * b * c") == "a * b * c"
    assert render("2*3*4") == "2*3*4"
    assert render("** not bold **") == "** not bold **"
    assert render("x == y") == "x == y"
  end

  test "snake_case and underscores are untouched" do
    assert render("Refactored user_id handling") == "Refactored user_id handling"
  end
end
