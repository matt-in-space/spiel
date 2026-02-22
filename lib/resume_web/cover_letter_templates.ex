defmodule ResumeWeb.CoverLetterTemplates do
  @moduledoc """
  Single registry for all cover letter templates.
  """

  @templates %{
    "formal" => ResumeWeb.CoverLetterTemplates.Formal,
    "modern" => ResumeWeb.CoverLetterTemplates.Modern,
    "minimal" => ResumeWeb.CoverLetterTemplates.Minimal,
    "elegant" => ResumeWeb.CoverLetterTemplates.Elegant
  }

  @template_options [
    {"Formal", "formal"},
    {"Modern", "modern"},
    {"Minimal", "minimal"},
    {"Elegant", "elegant"}
  ]

  @doc "Returns a map of template key => module."
  def templates, do: @templates

  @doc "Returns a list of {display_name, key} tuples for dropdowns."
  def template_options, do: @template_options

  @doc "Looks up a template module by key, defaulting to Formal."
  def get(key) do
    Map.get(@templates, key, ResumeWeb.CoverLetterTemplates.Formal)
  end
end
