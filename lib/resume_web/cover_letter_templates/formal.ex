defmodule ResumeWeb.CoverLetterTemplates.Formal do
  @moduledoc """
  Formal cover letter template — serif font (Georgia), traditional spacing.
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
      font-family: Georgia, "Times New Roman", Times, serif !important;
      color: #222 !important;
    }

    .cover-letter {
      font-size: 11pt;
      line-height: 1.6;
    }

    .cover-letter .cl-greeting {
      margin-bottom: 16pt;
      font-size: 11pt;
    }

    .cover-letter .cl-opening {
      margin-bottom: 12pt;
      text-indent: 0;
    }

    .cover-letter .cl-body p {
      margin: 0 0 12pt 0;
      text-indent: 0;
    }

    .cover-letter .cl-closing {
      margin-bottom: 24pt;
    }

    .cover-letter .cl-signature {
      line-height: 1.4;
    }
    """
  end
end
