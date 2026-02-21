defmodule Resume.JobPostings do
  @moduledoc """
  Fetches and extracts text content from job posting URLs.
  """

  require Logger

  @doc """
  Fetches a job posting URL and extracts the text content.

  Returns `{:ok, text}` or `{:error, reason}`.

  ## Options

  Accepts any `Req` options (e.g. `plug:` for testing).
  """
  def fetch_text(url, opts \\ []) do
    opts = Keyword.merge(base_req_opts(), opts)

    case fetch_from_ats_api(url, opts) do
      {:ok, _text} = success -> success
      :not_ats -> fetch_text_html(url, opts)
      {:error, _reason} -> fetch_text_html(url, opts)
    end
  end

  defp base_req_opts do
    Application.get_env(:resume, :job_postings_req_opts, [])
  end

  defp fetch_text_html(url, opts) do
    req_opts = Keyword.merge([max_redirects: 5, receive_timeout: 15_000], opts)

    case Req.get(url, req_opts) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        text = extract_text(body)

        if usable_text?(text) do
          {:ok, text}
        else
          Logger.warning("Job posting URL returned unusable content: #{url}")
          {:error, :unusable_content}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        Logger.error("Failed to fetch job posting from #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ATS API sniffing — try structured APIs before falling back to HTML scraping.

  @greenhouse_hosts ~w(boards.greenhouse.io job-boards.greenhouse.io)

  defp fetch_from_ats_api(url, opts) do
    uri = URI.parse(url)

    cond do
      uri.host in @greenhouse_hosts -> fetch_greenhouse(uri, opts)
      uri.host == "jobs.lever.co" -> fetch_lever(uri, opts)
      true -> :not_ats
    end
  end

  defp fetch_greenhouse(uri, opts) do
    case Path.split(uri.path || "") do
      ["/" | [board, "jobs", id | _]] ->
        api_url = "https://boards-api.greenhouse.io/v1/boards/#{board}/jobs/#{id}"
        req_opts = Keyword.merge([receive_timeout: 10_000], opts)

        case Req.get(api_url, req_opts) do
          {:ok, %Req.Response{status: 200, body: %{"content" => content}}}
          when is_binary(content) ->
            text = extract_text(content)
            if usable_text?(text), do: {:ok, text}, else: {:error, :unusable_content}

          {:ok, %Req.Response{status: status}} ->
            Logger.warning("Greenhouse API returned #{status} for #{uri}")
            {:error, {:http_status, status}}

          {:error, reason} ->
            Logger.warning("Greenhouse API error for #{uri}: #{inspect(reason)}")
            {:error, reason}
        end

      _ ->
        :not_ats
    end
  end

  defp fetch_lever(uri, opts) do
    case Path.split(uri.path || "") do
      ["/" | [company, posting_id | _]] ->
        api_url = "https://api.lever.co/v0/postings/#{company}/#{posting_id}"
        req_opts = Keyword.merge([receive_timeout: 10_000], opts)

        case Req.get(api_url, req_opts) do
          {:ok, %Req.Response{status: 200, body: %{"descriptionPlain" => text}}}
          when is_binary(text) ->
            text = String.trim(text)
            if usable_text?(text), do: {:ok, text}, else: {:error, :unusable_content}

          {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
            Logger.warning("Lever API response missing descriptionPlain for #{uri}")
            {:error, :unusable_content}

          {:ok, %Req.Response{status: status}} ->
            Logger.warning("Lever API returned #{status} for #{uri}")
            {:error, {:http_status, status}}

          {:error, reason} ->
            Logger.warning("Lever API error for #{uri}: #{inspect(reason)}")
            {:error, reason}
        end

      _ ->
        :not_ats
    end
  end

  defp extract_text(html) do
    html
    |> remove_elements(~r/<script[^>]*>.*?<\/script>/si)
    |> remove_elements(~r/<style[^>]*>.*?<\/style>/si)
    |> remove_elements(~r/<nav[^>]*>.*?<\/nav>/si)
    |> remove_elements(~r/<footer[^>]*>.*?<\/footer>/si)
    |> remove_elements(~r/<header[^>]*>.*?<\/header>/si)
    |> String.replace(~r/<br\s*\/?>/, "\n")
    |> String.replace(~r/<\/(?:p|div|h[1-6]|li|tr)>/, "\n")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/&nbsp;/, " ")
    |> String.replace(~r/&amp;/, "&")
    |> String.replace(~r/&lt;/, "<")
    |> String.replace(~r/&gt;/, ">")
    |> String.replace(~r/&#\d+;/, "")
    |> String.replace(~r/[ \t]+/, " ")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
    |> truncate(20_000)
  end

  @gate_patterns [
    ~r/javascript (?:is )?(?:required|must be enabled|needs to be enabled|not enabled)/i,
    ~r/enable javascript/i,
    ~r/please (?:sign|log) ?in/i,
    ~r/you (?:must|need to) (?:sign|log) ?in/i,
    ~r/not authenticated/i,
    ~r/access denied/i,
    ~r/verify you(?:'re| are) (?:a )?human/i,
    ~r/checking your browser/i,
    ~r/captcha/i
  ]

  defp usable_text?(text) do
    String.length(text) >= 50 and not Enum.any?(@gate_patterns, &Regex.match?(&1, text))
  end

  defp remove_elements(html, pattern), do: String.replace(html, pattern, " ")

  defp truncate(text, max_length) when byte_size(text) <= max_length, do: text
  defp truncate(text, max_length), do: String.slice(text, 0, max_length)
end
