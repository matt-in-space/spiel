defmodule ResumeWeb.ResumeTemplates.Helpers do
  @moduledoc """
  Shared helper functions for resume templates.
  """

  # Inline emphasis markers. Content may not contain "<" so that a marker can
  # never wrap around (and mis-nest with) a tag produced by an earlier pass.
  # Escaped user text never contains a literal "<", only "&lt;".
  # (Functions rather than module attributes: OTP 28 can't store compiled
  # regexes in attributes.)
  defp bold_re, do: ~r/\*\*(?=\S)([^<]+?)(?<=\S)\*\*/u
  defp highlight_re, do: ~r/==(?=\S)([^<]+?)(?<=\S)==/u
  defp italic_re, do: ~r/(?<![\*\w])\*(?=[^\s\*])([^<\*]+?)(?<=[^\s\*])\*(?![\*\w])/u

  @doc """
  Renders inline emphasis markers in resume text as safe HTML.

  Supported markers:

    * `**text**` — bold (`<strong>`)
    * `*text*` — italic (`<em>`)
    * `==text==` — highlight (`<mark>`)

  The input is HTML-escaped first, so any raw HTML typed by a user or
  produced by the LLM is shown as text rather than interpreted.
  """
  def inline_format(nil), do: {:safe, ""}

  def inline_format(text) when is_binary(text) do
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    html =
      escaped
      |> then(&Regex.replace(bold_re(), &1, "<strong>\\1</strong>"))
      |> then(&Regex.replace(highlight_re(), &1, "<mark>\\1</mark>"))
      |> then(&Regex.replace(italic_re(), &1, "<em>\\1</em>"))

    {:safe, html}
  end

  @doc """
  Shared CSS for inline emphasis produced by `inline_format/1`. Each template's
  `css/0` includes it so the preview, gallery, and PDF all style it the same.
  """
  def inline_format_css do
    """
    .resume strong, .cover-letter strong { font-weight: 700; }
    .resume em, .cover-letter em { font-style: italic; }
    .resume mark, .cover-letter mark {
      background-color: #fdf0a6;
      padding: 0 0.12em;
      border-radius: 2px;
      -webkit-box-decoration-break: clone;
      box-decoration-break: clone;
    }
    """
  end

  @doc "Formats a FlexDate struct to a human-readable string."
  def format_flex_date(nil), do: ""

  def format_flex_date(%{year: year, month: month}) when is_integer(month) do
    month_name = Calendar.strftime(%Date{year: year, month: month, day: 1}, "%b")
    "#{month_name} #{year}"
  end

  def format_flex_date(%{year: year}), do: "#{year}"

  @doc "Returns display text for a website entry."
  def website_display(%{type: "linkedin"}), do: "LinkedIn"
  def website_display(%{type: "github"}), do: "GitHub"
  def website_display(%{type: type} = w) when type in ["website", "custom"], do: w.label || w.url
  def website_display(w), do: Map.get(w, :label) || Map.get(w, :url, "")

  @doc "Formats a date range from two FlexDate structs."
  def format_date_range(start_date, end_date, current) do
    start_str = format_flex_date(start_date)
    end_str = if current, do: "Present", else: format_flex_date(end_date)

    case {start_str, end_str} do
      {"", ""} -> ""
      {s, ""} -> s
      {"", e} -> e
      {s, e} -> "#{s} — #{e}"
    end
  end
end
