defmodule Resume.PDF do
  @moduledoc """
  Behaviour for PDF rendering providers.
  """

  @callback render(html :: String.t(), css :: String.t(), opts :: keyword()) ::
              {:ok, binary()} | {:error, term()}

  @doc """
  Calls the configured PDF adapter's `render/3`.
  """
  def render(html, css, opts \\ []) do
    adapter().render(html, css, opts)
  end

  defp adapter do
    Application.fetch_env!(:resume, :pdf_adapter)
  end
end
