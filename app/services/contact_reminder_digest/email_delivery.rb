class ContactReminderDigest::EmailDelivery
  CurrentMembership = Struct.new(:count, :preview_people, keyword_init: true)

  def self.call(digest_id:, at: Time.current, transport: nil)
    new(digest_id:, at:, transport:).call
  end

  def initialize(digest_id:, at:, transport:)
    @digest_id = digest_id
    @at = at
    @transport = transport
  end

  def call
    return unless (claim = ContactReminderDigest::Claim.call(digest_id:, at:))

    @claim_token = claim.token
    digest = claim.digest
    membership = current_membership(digest)
    return cancel_digest(digest) if membership.count.zero?

    result = transport.deliver(
      message: ReminderMailer.with(
        digest:, people: membership.preview_people, count: membership.count
      ).contact_digest,
      delivery_id: "contact-reminder-digest/#{digest.id}"
    )
    mark_delivered(digest)
    result
  rescue MailTransports::DeliveryError => error
    mark_failed(digest)
    Rails.logger.error("Contact reminder digest delivery failed id=#{digest_id} error=#{error.class}")
    raise
  rescue StandardError => error
    mark_failed(digest)
    Rails.logger.error("Contact reminder digest delivery failed id=#{digest_id} error=#{error.class}")
    raise
  end

  private

  attr_reader :digest_id, :at, :claim_token

  def current_membership(digest)
    count = 0
    preview_deliveries = []

    member_deliveries(digest).in_batches(of: batch_size) do |batch|
      deliveries = batch.preload(:source).to_a
      current = ReminderDelivery::Reconciler.current(deliveries:, user: digest.user, at:)
      cancel_deliveries(deliveries - current)
      count += current.size
      preview_deliveries = (preview_deliveries + current).sort_by do |delivery|
        [ delivery.reminder_on, PersonNameNormalizer.call(delivery.source.name), delivery.source.id ]
      end.first(preview_limit)
    end

    CurrentMembership.new(count:, preview_people: preview_deliveries.map(&:source))
  end

  def member_deliveries(digest)
    digest.reminder_deliveries.where(
      status: [ ReminderDelivery::PENDING_STATUS, ReminderDelivery::FAILED_STATUS ]
    )
  end

  def cancel_deliveries(deliveries)
    return if deliveries.empty?

    ReminderDelivery.where(id: deliveries.map(&:id)).update_all(
      status: ReminderDelivery::CANCELED_STATUS,
      canceled_at: at,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at
    )
  end

  def mark_delivered(digest)
    ContactReminderDigest.transaction do
      updated = ContactReminderDigest.where(id: digest.id, claim_token:).update_all(
        status: ContactReminderDigest::DELIVERED_STATUS,
        delivered_at: at,
        failed_at: nil,
        claimed_at: nil,
        claim_token: nil,
        updated_at: at
      )
      next unless updated == 1

      ReminderDelivery.where(
        contact_reminder_digest_id: digest.id,
        status: [ ReminderDelivery::PENDING_STATUS, ReminderDelivery::FAILED_STATUS ]
      ).update_all(
        status: ReminderDelivery::DELIVERED_STATUS,
        delivered_at: at,
        failed_at: nil,
        claimed_at: nil,
        claim_token: nil,
        updated_at: at
      )
    end
  end

  def cancel_digest(digest)
    update_claimed_digest(digest,
      status: ContactReminderDigest::CANCELED_STATUS,
      canceled_at: at,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at)
    nil
  end

  def mark_failed(digest)
    return unless digest && claim_token

    update_claimed_digest(digest,
      status: ContactReminderDigest::FAILED_STATUS,
      failed_at: at,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at)
  end

  def update_claimed_digest(digest, attributes)
    ContactReminderDigest.where(id: digest.id, claim_token:).update_all(attributes)
  end

  def transport
    @transport ||= MailTransports.fetch(Rails.application.config.x.reminder_mail_transport)
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end

  def preview_limit
    Rails.application.config.x.contact_reminder_digest_preview_limit
  end
end
