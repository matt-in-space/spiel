defmodule ResumeWeb.CoverLetterTemplates.Modern do
  @moduledoc """
  Modern cover letter template — sans-serif (Inter), clean with subtle accent.
  """

  use ResumeWeb, :html

  attr :data, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="cover-letter">
      <div class="cl-greeting" data-section="greeting">{@data.greeting}</div>
      <div class="cl-opening" data-section="opening">{@data.opening}</div>
      <div class="cl-body" data-section="body">
        <p :for={paragraph <- @data.body || []}>{paragraph}</p>
      </div>
      <div class="cl-closing" data-section="closing">{@data.closing}</div>
      <div class="cl-signature" data-section="signature">
        <span :for={line <- String.split(@data.signature || "", "\n")}>{line}<br /></span>
      </div>
    </div>
    """
  end

  def css do
    """
    @page {
      size: letter;
      margin: 1in;
    }

    .cover-letter, .cover-letter * {
      font-family: Inter, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif !important;
      color: #333 !important;
    }

    .cover-letter {
      font-size: 10.5pt;
      line-height: 1.65;
    }

    .cover-letter .cl-greeting {
      margin-bottom: 14pt;
      font-size: 10.5pt;
      color: #1a1a1a !important;
      padding-bottom: 10pt;
      border-bottom: 2pt solid #4a90d9;
    }

    .cover-letter .cl-opening {
      margin-bottom: 10pt;
    }

    .cover-letter .cl-body p {
      margin: 0 0 10pt 0;
    }

    .cover-letter .cl-closing {
      margin-bottom: 20pt;
    }

    .cover-letter .cl-signature {
      font-weight: 500;
      line-height: 1.4;
      color: #1a1a1a !important;
    }
    """
  end
end
