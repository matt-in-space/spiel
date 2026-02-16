defmodule ResumeWeb.ResumeTemplates.Helpers do
  @moduledoc """
  Shared helper functions for resume templates.
  """

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
