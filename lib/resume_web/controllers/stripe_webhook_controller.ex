defmodule ResumeWeb.StripeWebhookController do
  use ResumeWeb, :controller

  require Logger

  alias Resume.{Accounts, Billing}
  alias Resume.Billing.Stripe

  def handle(conn, _params) do
    raw_body = conn.private[:raw_body] || ""
    signature = Plug.Conn.get_req_header(conn, "stripe-signature") |> List.first("")
    secret = Application.fetch_env!(:resume, :stripe_webhook_secret)

    case Stripe.verify_webhook_signature(raw_body, signature, secret) do
      :ok ->
        process_event(conn)

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "Invalid signature"})
    end
  end

  defp process_event(conn) do
    body = conn.body_params

    case body["type"] do
      "checkout.session.completed" ->
        handle_checkout_completed(conn, body["data"]["object"])

      _ ->
        json(conn, %{ok: true})
    end
  end

  defp handle_checkout_completed(conn, session) do
    user_id = String.to_integer(session["client_reference_id"])

    payment_attrs = %{
      user_id: user_id,
      stripe_checkout_session_id: session["id"],
      stripe_payment_intent_id: session["payment_intent"],
      amount_cents: session["amount_total"],
      currency: session["currency"] || "usd",
      status: "completed"
    }

    with {:ok, _payment} <- Billing.record_payment(payment_attrs),
         user <- Accounts.get_user!(user_id),
         {:ok, _user} <- Billing.activate_pass(user) do
      json(conn, %{ok: true})
    else
      {:error, reason} ->
        Logger.error("Failed to process checkout: #{inspect(reason)}")
        conn |> put_status(500) |> json(%{error: "Processing failed"})
    end
  end
end
