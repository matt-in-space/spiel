defmodule ResumeWeb.CoverLetterTemplates.Minimal do
  @moduledoc """
  Minimal cover letter template — Helvetica, generous whitespace.
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
      margin: 1.15in 1in;
    }

    .cover-letter, .cover-letter * {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important;
      color: #444 !important;
    }

    .cover-letter {
      font-size: 10pt;
      line-height: 1.75;
    }

    .cover-letter .cl-greeting {
      margin-bottom: 18pt;
      font-size: 10pt;
      color: #222 !important;
    }

    .cover-letter .cl-opening {
      margin-bottom: 14pt;
      color: #333 !important;
    }

    .cover-letter .cl-body p {
      margin: 0 0 14pt 0;
    }

    .cover-letter .cl-closing {
      margin-bottom: 28pt;
    }

    .cover-letter .cl-signature {
      line-height: 1.4;
      color: #222 !important;
    }
    """
  end
end
