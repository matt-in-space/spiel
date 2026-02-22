defmodule ResumeWeb.CoverLetterTemplates.Elegant do
  @moduledoc """
  Elegant cover letter template — refined serif (Lora/Georgia), thin rule dividers.
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
      <hr class="cl-rule" />
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
      font-family: Lora, Georgia, "Times New Roman", serif !important;
      color: #2c2c2c !important;
    }

    .cover-letter {
      font-size: 10.5pt;
      line-height: 1.7;
    }

    .cover-letter .cl-greeting {
      margin-bottom: 16pt;
      font-size: 10.5pt;
      font-style: italic;
      color: #555 !important;
    }

    .cover-letter .cl-opening {
      margin-bottom: 12pt;
    }

    .cover-letter .cl-body p {
      margin: 0 0 12pt 0;
    }

    .cover-letter .cl-closing {
      margin-bottom: 16pt;
    }

    .cover-letter .cl-rule {
      border: none;
      border-top: 0.5pt solid #ccc;
      margin: 0 0 16pt 0;
      width: 40%;
    }

    .cover-letter .cl-signature {
      font-style: italic;
      line-height: 1.4;
      color: #444 !important;
    }
    """
  end
end
