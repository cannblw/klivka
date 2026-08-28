require "test_helper"

class ContactReminderDigestTest < ActiveSupport::TestCase
  test "allows one digest for an account on each local delivery date" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))
    duplicate = ContactReminderDigest.new(user: users(:one), delivery_on: digest.delivery_on)

    assert_not_predicate duplicate, :valid?
    assert duplicate.errors.of_kind?(:delivery_on, :taken)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }

    assert_predicate ContactReminderDigest.new(user: users(:two), delivery_on: digest.delivery_on), :valid?
  end

  test "requires supported lifecycle values at model and database boundaries" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))

    digest.status = "queued"
    digest.attempts = -1
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:status, :inclusion)
    assert digest.errors.of_kind?(:attempts, :greater_than_or_equal_to)

    assert_raises(ActiveRecord::StatementInvalid) { digest.update_column(:status, "queued") }
    assert_raises(ActiveRecord::StatementInvalid) { digest.update_column(:attempts, -1) }
  end

  test "requires complete claim metadata at model and database boundaries" do
    digest = ContactReminderDigest.create!(user: users(:one), delivery_on: Date.new(2026, 8, 28))

    digest.claimed_at = Time.utc(2026, 8, 28, 8)
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:claim_token, :blank)

    digest.claimed_at = nil
    digest.claim_token = "claim-token"
    assert_not_predicate digest, :valid?
    assert digest.errors.of_kind?(:claimed_at, :blank)

    assert_raises(ActiveRecord::StatementInvalid) do
      digest.update_columns(claimed_at: Time.utc(2026, 8, 28, 8), claim_token: nil)
    end
  end

  test "deleting an account removes its digest history" do
    user = User.create!(email_address: "digest-owner@example.com", password: "password", time_zone: "UTC")
    ContactReminderDigest.create!(user:, delivery_on: Date.new(2026, 8, 28))

    assert_difference [ "User.count", "ContactReminderDigest.count" ], -1 do
      user.destroy!
    end
  end
end
