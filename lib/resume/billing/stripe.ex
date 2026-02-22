defmodule Resume.Billing.Stripe do
  @moduledoc """
  Stripe API client using Req. Handles Checkout Session creation and webhook verification.
  """

  @doc """
  Creates a Stripe Checkout Session for a one-time $5 payment.
  """
  def create_checkout_session(user, success_url, cancel_url) do
    Req.post(
      url: "https://api.stripe.com/v1/checkout/sessions",
      headers: [{"authorization", "Bearer #{secret_key()}"}],
      form: [
        {"mode", "payment"},
        {"line_items[0][price]", price_id()},
        {"line_items[0][quantity]", "1"},
        {"success_url", success_url},
        {"cancel_url", cancel_url},
        {"client_reference_id", to_string(user.id)},
        {"customer_email", user.email}
      ]
    )
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body["url"]}

      {:ok, %{body: body}} ->
        {:error, body["error"]["message"] || "Stripe error"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Verifies a Stripe webhook signature using HMAC-SHA256.
  Returns `:ok` or `:error`.
  """
  def verify_webhook_signature(payload, signature_header, secret) do
    parts =
      signature_header
      |> String.split(",")
      |> Enum.map(fn part ->
        [key, value] = String.split(part, "=", parts: 2)
        {String.trim(key), String.trim(value)}
      end)
      |> Map.new()

    timestamp = parts["t"]
    v1_signature = parts["v1"]

    with {timestamp, v1_signature} when not is_nil(timestamp) and not is_nil(v1_signature) <-
           {timestamp, v1_signature},
         true <- valid_hmac?(timestamp, payload, secret, v1_signature),
         true <- fresh_timestamp?(timestamp) do
      :ok
    else
      _ -> :error
    end
  end

  @max_age_seconds 300

  defp valid_hmac?(timestamp, payload, secret, v1_signature) do
    signed_payload = "#{timestamp}.#{payload}"

    expected =
      :crypto.mac(:hmac, :sha256, secret, signed_payload) |> Base.encode16(case: :lower)

    Plug.Crypto.secure_compare(expected, v1_signature)
  end

  defp fresh_timestamp?(timestamp) do
    case Integer.parse(timestamp) do
      {ts, ""} -> abs(System.system_time(:second) - ts) <= @max_age_seconds
      _ -> false
    end
  end

  defp secret_key do
    Application.fetch_env!(:resume, :stripe_secret_key)
  end

  defp price_id do
    Application.fetch_env!(:resume, :stripe_price_id)
  end
end
