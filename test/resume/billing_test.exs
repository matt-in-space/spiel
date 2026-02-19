defmodule Resume.BillingTest do
  use Resume.DataCase

  alias Resume.Billing
  alias Resume.Accounts.User

  setup do
    user = Resume.AccountsFixtures.user_fixture()
    %{user: user}
  end

  describe "check_allowance/2" do
    test "allows unlimited users without limits", %{user: user} do
      {:ok, user} = Billing.grant_unlimited(user)
      assert :ok = Billing.check_allowance(user, :generation)
    end

    test "allows admin users without limits", %{user: user} do
      user = %{user | role: :admin}
      assert :ok = Billing.check_allowance(user, :generation)
    end

    test "allows free users within limit", %{user: user} do
      assert :ok = Billing.check_allowance(user, :generation)
    end

    test "rejects free users at generation limit", %{user: user} do
      insert_llm_calls(user.id, "generator", 2)
      assert {:error, :limit_reached, msg} = Billing.check_allowance(user, :generation)
      assert msg =~ "resume generations"
    end

    test "rejects free users at adjustment limit", %{user: user} do
      insert_llm_calls(user.id, "feedback", 3)
      assert {:error, :limit_reached, msg} = Billing.check_allowance(user, :adjustment)
      assert msg =~ "resume adjustments"
    end

    test "rejects free users at fact_update limit", %{user: user} do
      insert_llm_calls(user.id, "facts", 3)
      assert {:error, :limit_reached, msg} = Billing.check_allowance(user, :fact_update)
      assert msg =~ "profile updates"
    end

    test "allows users with active pass even past free limits", %{user: user} do
      insert_llm_calls(user.id, "generator", 10)
      {:ok, user} = Billing.activate_pass(user)
      assert :ok = Billing.check_allowance(user, :generation)
    end
  end

  describe "has_active_pass?/1" do
    test "returns false for nil pass_expires_at", %{user: user} do
      refute Billing.has_active_pass?(user)
    end

    test "returns true for future pass_expires_at", %{user: user} do
      {:ok, user} = Billing.activate_pass(user)
      assert Billing.has_active_pass?(user)
    end

    test "returns false for expired pass", %{user: user} do
      past = DateTime.add(DateTime.utc_now(), -1, :day)

      user =
        user
        |> User.billing_changeset(%{access_level: "pass", pass_expires_at: past})
        |> Repo.update!()

      refute Billing.has_active_pass?(user)
    end
  end

  describe "activate_pass/1" do
    test "sets pass_expires_at 30 days from now", %{user: user} do
      {:ok, updated} = Billing.activate_pass(user)
      assert updated.access_level == "pass"
      assert updated.pass_expires_at != nil

      diff = DateTime.diff(updated.pass_expires_at, DateTime.utc_now(), :day)
      assert diff >= 29 and diff <= 30
    end

    test "extends from current expiry if pass is active", %{user: user} do
      {:ok, user} = Billing.activate_pass(user)
      original_expiry = user.pass_expires_at

      {:ok, extended} = Billing.activate_pass(user)
      diff = DateTime.diff(extended.pass_expires_at, original_expiry, :day)
      assert diff >= 29 and diff <= 30
    end
  end

  describe "grant_unlimited/1 and revoke_unlimited/1" do
    test "grants and revokes unlimited access", %{user: user} do
      {:ok, user} = Billing.grant_unlimited(user)
      assert user.access_level == "unlimited"
      assert Billing.has_unlimited_access?(user)

      {:ok, user} = Billing.revoke_unlimited(user)
      assert user.access_level == "free"
      refute Billing.has_unlimited_access?(user)
    end
  end

  describe "usage_this_month/2" do
    test "counts only current month's calls", %{user: user} do
      insert_llm_calls(user.id, "generator", 2)
      assert Billing.usage_this_month(user.id, :generation) == 2
    end

    test "counts both facts and facts_input for fact_update", %{user: user} do
      insert_llm_calls(user.id, "facts", 1)
      insert_llm_calls(user.id, "facts_input", 2)
      assert Billing.usage_this_month(user.id, :fact_update) == 3
    end
  end

  describe "usage_summary/1" do
    test "returns usage map", %{user: user} do
      insert_llm_calls(user.id, "generator", 1)
      summary = Billing.usage_summary(user)
      assert summary.generation.used == 1
      assert summary.generation.limit == 2
    end
  end

  describe "record_payment/1" do
    test "creates a payment", %{user: user} do
      attrs = %{
        user_id: user.id,
        stripe_checkout_session_id: "cs_test_123",
        amount_cents: 500,
        currency: "usd",
        status: "completed"
      }

      assert {:ok, payment} = Billing.record_payment(attrs)
      assert payment.amount_cents == 500
    end

    test "is idempotent on session ID", %{user: user} do
      attrs = %{
        user_id: user.id,
        stripe_checkout_session_id: "cs_test_456",
        amount_cents: 500,
        currency: "usd",
        status: "completed"
      }

      {:ok, first} = Billing.record_payment(attrs)
      {:ok, second} = Billing.record_payment(attrs)
      assert first.id == second.id
    end
  end

  defp insert_llm_calls(user_id, caller, count) do
    for _ <- 1..count do
      %Resume.LLM.Call{}
      |> Resume.LLM.Call.changeset(%{
        user_id: user_id,
        caller: caller,
        model: "test-model"
      })
      |> Repo.insert!()
    end
  end
end
