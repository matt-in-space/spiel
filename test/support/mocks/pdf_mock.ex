defmodule Resume.PDF.Mock do
  @moduledoc """
  Mock PDF adapter for tests.
  """

  @behaviour Resume.PDF

  @impl true
  def render(_html, _css, _opts \\ []) do
    {:ok, "%PDF-1.4 mock"}
  end
end
