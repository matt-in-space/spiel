defmodule ResumeWeb.StripeWebhookControllerTest do
  use ResumeWeb.ConnCase

  import Ecto.Query
  alias Resume.Billing

  @webhook_secret "whsec_test_secret"

  setup do
    Application.put_env(:resume, :stripe_webhook_secret, @webhook_secret)
    user = Resume.AccountsFixtures.user_fixture()
    %{user: user}
  end

  describe "POST /api/stripe/webhook" do
    test "processes checkout.session.completed and activates pass", %{conn: conn, user: user} do
      payload =
        Jason.encode!(%{
          "type" => "checkout.session.completed",
          "data" => %{
            "object" => %{
              "id" => "cs_test_#{System.unique_integer([:positive])}",
              "client_reference_id" => to_string(user.id),
              "payment_intent" => "pi_test_123",
              "amount_total" => 500,
              "currency" => "usd"
            }
          }
        })

      signature = sign_payload(payload)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("stripe-signature", signature)
        |> put_private(:raw_body, payload)
        |> post("/api/stripe/webhook", Jason.decode!(payload))

      assert json_response(conn, 200)["ok"] == true

      updated_user = Resume.Accounts.get_user!(user.id)
      assert updated_user.access_level == "pass"
      assert updated_user.pass_expires_at != nil
    end

    test "rejects invalid signature", %{conn: conn} do
      payload = Jason.encode!(%{"type" => "checkout.session.completed"})

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("stripe-signature", "t=123,v1=invalid")
        |> put_private(:raw_body, payload)
        |> post("/api/stripe/webhook", Jason.decode!(payload))

      assert json_response(conn, 400)["error"] == "Invalid signature"
    end

    test "is idempotent — second webhook with same session_id succeeds", %{
      conn: _conn,
      user: user
    } do
      session_id = "cs_test_idempotent_#{System.unique_integer([:positive])}"

      payload =
        Jason.encode!(%{
          "type" => "checkout.session.completed",
          "data" => %{
            "object" => %{
              "id" => session_id,
              "client_reference_id" => to_string(user.id),
              "payment_intent" => "pi_test_idem",
              "amount_total" => 500,
              "currency" => "usd"
            }
          }
        })

      signature = sign_payload(payload)

      for _ <- 1..2 do
        resp =
          build_conn()
          |> put_req_header("content-type", "application/json")
          |> put_req_header("stripe-signature", signature)
          |> put_private(:raw_body, payload)
          |> post("/api/stripe/webhook", Jason.decode!(payload))

        assert json_response(resp, 200)["ok"] == true
      end

      payments =
        Resume.Repo.all(
          from(p in Billing.Payment,
            where: p.stripe_checkout_session_id == ^session_id
          )
        )

      assert length(payments) == 1
    end
  end

  defp sign_payload(payload) do
    timestamp = to_string(System.system_time(:second))
    signed = "#{timestamp}.#{payload}"

    signature =
      :crypto.mac(:hmac, :sha256, @webhook_secret, signed) |> Base.encode16(case: :lower)

    "t=#{timestamp},v1=#{signature}"
  end
end
