require "test_helper"

class ContactReminderDigest::ClaimTest < ActiveSupport::TestCase
  setup do
    @at = Time.utc(2026, 8, 28, 8)
    @digest = ContactReminderDigest.create!(user: users(:one), delivery_on: @at.to_date)
  end

  test "claims a pending digest transactionally" do
    result = ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)

    assert_equal @digest, result.digest
    assert_equal result.token, @digest.reload.claim_token
    assert_equal @at, @digest.claimed_at
    assert_equal 1, @digest.attempts
  end

  test "does not claim a digest while another claim is active" do
    @digest.update!(claimed_at: @at - 1.minute, claim_token: "active-claim", attempts: 1)

    assert_nil ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)
    assert_equal "active-claim", @digest.reload.claim_token
    assert_equal 1, @digest.attempts
  end

  test "reclaims a digest after an abandoned claim expires" do
    stale_time = @at - Rails.application.config.x.reminder_delivery_claim_timeout - 1.second
    @digest.update!(claimed_at: stale_time, claim_token: "stale-claim", attempts: 1)

    result = ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)

    assert_not_equal "stale-claim", result.token
    assert_equal result.token, @digest.reload.claim_token
    assert_equal 2, @digest.attempts
  end

  test "does not claim a completed digest" do
    @digest.update!(status: ContactReminderDigest::DELIVERED_STATUS, delivered_at: @at)

    assert_nil ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)
  end

  test "marks an abandoned pending digest failed after attempts are exhausted" do
    @digest.update!(
      attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
      claimed_at: @at - Rails.application.config.x.reminder_delivery_claim_timeout - 1.second,
      claim_token: "stale-claim"
    )

    assert_nil ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)

    assert_equal ContactReminderDigest::FAILED_STATUS, @digest.reload.status
    assert_equal @at, @digest.failed_at
    assert_nil @digest.claimed_at
    assert_nil @digest.claim_token
  end

  test "clears an abandoned retry claim after attempts are exhausted" do
    @digest.update!(
      status: ContactReminderDigest::FAILED_STATUS,
      failed_at: @at - 1.hour,
      attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
      claimed_at: @at - Rails.application.config.x.reminder_delivery_claim_timeout - 1.second,
      claim_token: "stale-retry"
    )

    assert_nil ContactReminderDigest::Claim.call(digest_id: @digest.id, at: @at)

    assert_equal @at, @digest.reload.failed_at
    assert_nil @digest.claimed_at
    assert_nil @digest.claim_token
  end
end
