defmodule Resume.LLM.Mock do
  @moduledoc """
  Mock LLM adapter for tests.
  """

  @behaviour Resume.LLM

  @impl true
  def complete(_prompt, _opts \\ []) do
    {:ok, ~s(["Mock fact about career", "Mock fact about skills"])}
  end
end
