defmodule Resume.Documents do
  @moduledoc """
  Text extraction from uploaded documents.
  """

  @doc """
  Extracts text from a file based on its content type.

  Supports `"text/plain"` (direct read) and `"application/pdf"` (via `pdftotext`).
  """
  @spec extract_text(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract_text(path, "text/plain") do
    {:ok, File.read!(path)}
  end

  def extract_text(path, "application/pdf") do
    case System.cmd("pdftotext", [path, "-"], stderr_to_stdout: true) do
      {text, 0} -> {:ok, text}
      {output, _code} -> {:error, "pdftotext failed: #{String.trim(output)}"}
    end
  rescue
    e in ErlangError -> {:error, "pdftotext not available: #{inspect(e)}"}
  end

  def extract_text(_path, content_type) do
    {:error, "unsupported content type: #{content_type}"}
  end
end
