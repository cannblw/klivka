require "securerandom"

class ContactReminderDigestClaim
  Result = Struct.new(:digest, :token, keyword_init: true)

  def self.call(digest_id:, at: Time.current)
    new(digest_id:, at:).call
  end

  def initialize(digest_id:, at:)
    @digest_id = digest_id
    @at = at
    @token = SecureRandom.uuid
  end

  def call
    ContactReminderDigest.transaction do
      digest = ContactReminderDigest.where(
        id: digest_id,
        status: [ ContactReminderDigest::PENDING_STATUS, ContactReminderDigest::FAILED_STATUS ]
      ).lock.first
      next unless digest
      next if active_claim?(digest)

      if digest.attempts >= retry_attempts
        finalize_exhausted_claim(digest)
        next
      end

      digest.update!(claimed_at: at, claim_token: token, attempts: digest.attempts + 1)
      Result.new(digest:, token:)
    end
  end

  private

  attr_reader :digest_id, :at, :token

  def active_claim?(digest)
    digest.claimed_at && digest.claimed_at >= at - claim_timeout
  end

  def finalize_exhausted_claim(digest)
    digest.update!(
      status: ContactReminderDigest::FAILED_STATUS,
      failed_at: at,
      claimed_at: nil,
      claim_token: nil
    )
  end

  def retry_attempts
    Rails.application.config.x.reminder_delivery_retry_attempts
  end

  def claim_timeout
    Rails.application.config.x.reminder_delivery_claim_timeout
  end
end
