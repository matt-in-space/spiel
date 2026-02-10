defmodule Resume.DocumentsTest do
  use ExUnit.Case, async: true

  alias Resume.Documents

  describe "extract_text/2" do
    test "reads plain text files" do
      path = Path.join(System.tmp_dir!(), "test_doc_#{System.unique_integer([:positive])}.txt")
      on_exit(fn -> File.rm(path) end)

      File.write!(path, "Hello, world!")
      assert {:ok, "Hello, world!"} = Documents.extract_text(path, "text/plain")
    end

    test "extracts text from a PDF" do
      # Minimal valid PDF with embedded text
      pdf_bytes =
        "%PDF-1.0\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj\n4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj\n5 0 obj<</Length 44>>stream\nBT /F1 12 Tf 100 700 Td (Hello PDF) Tj ET\nendstream\nendobj\nxref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000266 00000 n \n0000000340 00000 n \ntrailer<</Size 6/Root 1 0 R>>\nstartxref\n434\n%%EOF\n"

      path = Path.join(System.tmp_dir!(), "test_doc_#{System.unique_integer([:positive])}.pdf")
      on_exit(fn -> File.rm(path) end)

      File.write!(path, pdf_bytes)

      case Documents.extract_text(path, "application/pdf") do
        {:ok, text} ->
          assert String.contains?(text, "Hello PDF")

        {:error, "pdftotext not available" <> _} ->
          :ok
      end
    end

    test "returns error for unsupported content type" do
      assert {:error, "unsupported content type: image/png"} =
               Documents.extract_text("/tmp/fake.png", "image/png")
    end
  end
end
