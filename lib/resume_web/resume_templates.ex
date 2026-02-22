defmodule ResumeWeb.ResumeTemplates do
  @moduledoc """
  Single registry for all resume templates. The gallery page, show page,
  and PDF controller all read from here.
  """

  @templates %{
    "default" => ResumeWeb.ResumeTemplates.Default,
    "mono" => ResumeWeb.ResumeTemplates.Mono,
    "fresh" => ResumeWeb.ResumeTemplates.Fresh,
    "executive" => ResumeWeb.ResumeTemplates.Executive,
    "elegant" => ResumeWeb.ResumeTemplates.Elegant,
    "classic" => ResumeWeb.ResumeTemplates.Classic,
    "flat" => ResumeWeb.ResumeTemplates.Flat,
    "kendall" => ResumeWeb.ResumeTemplates.Kendall,
    "editorial" => ResumeWeb.ResumeTemplates.Editorial,
    "typewriter" => ResumeWeb.ResumeTemplates.Typewriter,
    "nordic" => ResumeWeb.ResumeTemplates.Nordic,
    "berlin" => ResumeWeb.ResumeTemplates.Berlin,
    "even" => ResumeWeb.ResumeTemplates.Even,
    "paper" => ResumeWeb.ResumeTemplates.Paper,
    "consultant" => ResumeWeb.ResumeTemplates.Consultant,
    "sidebar" => ResumeWeb.ResumeTemplates.Sidebar,
    "stackoverflow" => ResumeWeb.ResumeTemplates.Stackoverflow,
    "academic" => ResumeWeb.ResumeTemplates.Academic,
    "minimalist" => ResumeWeb.ResumeTemplates.Minimalist,
    "macchiato" => ResumeWeb.ResumeTemplates.Macchiato
  }

  @template_options [
    {"Default", "default"},
    {"Mono", "mono"},
    {"Fresh", "fresh"},
    {"Executive", "executive"},
    {"Elegant", "elegant"},
    {"Classic", "classic"},
    {"Flat", "flat"},
    {"Kendall", "kendall"},
    {"Editorial", "editorial"},
    {"Typewriter", "typewriter"},
    {"Nordic", "nordic"},
    {"Berlin", "berlin"},
    {"Even", "even"},
    {"Paper", "paper"},
    {"Consultant", "consultant"},
    {"Sidebar", "sidebar"},
    {"Stack Overflow", "stackoverflow"},
    {"Academic", "academic"},
    {"Minimalist", "minimalist"},
    {"Macchiato", "macchiato"}
  ]

  @doc "Returns a map of template key => module."
  def templates, do: @templates

  @doc "Returns a list of {display_name, key} tuples for dropdowns."
  def template_options, do: @template_options

  @doc "Looks up a template module by key, defaulting to Default."
  def get(key) do
    Map.get(@templates, key, ResumeWeb.ResumeTemplates.Default)
  end
end
