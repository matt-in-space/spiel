defmodule Resume.Billing.StripeTest do
  use ExUnit.Case, async: true

  alias Resume.Billing.Stripe

  describe "verify_webhook_signature/3" do
    test "returns :ok for valid signature with fresh timestamp" do
      secret = "whsec_test_secret"
      payload = ~s({"type":"checkout.session.completed"})
      timestamp = to_string(System.system_time(:second))

      signed = "#{timestamp}.#{payload}"
      expected = :crypto.mac(:hmac, :sha256, secret, signed) |> Base.encode16(case: :lower)
      signature = "t=#{timestamp},v1=#{expected}"

      assert :ok = Stripe.verify_webhook_signature(payload, signature, secret)
    end

    test "returns :error for invalid signature" do
      secret = "whsec_test_secret"
      payload = ~s({"type":"checkout.session.completed"})
      timestamp = to_string(System.system_time(:second))
      signature = "t=#{timestamp},v1=invalidsignature"

      assert :error = Stripe.verify_webhook_signature(payload, signature, secret)
    end

    test "returns :error for stale timestamp" do
      secret = "whsec_test_secret"
      payload = ~s({"type":"checkout.session.completed"})
      stale_timestamp = to_string(System.system_time(:second) - 600)

      signed = "#{stale_timestamp}.#{payload}"
      expected = :crypto.mac(:hmac, :sha256, secret, signed) |> Base.encode16(case: :lower)
      signature = "t=#{stale_timestamp},v1=#{expected}"

      assert :error = Stripe.verify_webhook_signature(payload, signature, secret)
    end

    test "returns :error for missing v1" do
      assert :error = Stripe.verify_webhook_signature("payload", "t=123", "secret")
    end

    test "returns :error for missing timestamp" do
      assert :error = Stripe.verify_webhook_signature("payload", "v1=abc", "secret")
    end
  end
end
