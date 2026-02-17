defmodule Resume.PDF.WeasyPrint do
  @moduledoc """
  WeasyPrint adapter for the PDF behaviour.

  Sends HTML and CSS to the WeasyPrint HTTP service and returns the PDF binary.
  """

  require Logger

  @behaviour Resume.PDF

  @impl true
  def render(html, _css, _opts \\ []) do
    base_url = weasyprint_url()
    %URI{host: host, port: port, scheme: scheme} = URI.parse(base_url)

    {url, connect_opts} =
      case :inet.getaddr(~c"#{host}", :inet6) do
        {:ok, ip} ->
          ip_str = :inet.ntoa(ip) |> to_string()
          url = "#{scheme}://[#{ip_str}]:#{port}/pdf"
          {url, [hostname: host]}

        {:error, _} ->
          {"#{base_url}/pdf", []}
      end

    case Req.post(url,
           body: html,
           headers: [{"content-type", "text/html"}],
           connect_options: connect_opts
         ) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("WeasyPrint returned #{status}: #{inspect(body)}")
        {:error, {:weasyprint, status, body}}

      {:error, reason} ->
        Logger.error("WeasyPrint request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp weasyprint_url do
    Application.fetch_env!(:resume, :weasyprint_url)
  end
end
