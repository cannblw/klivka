require "securerandom"

class ReminderDeliveryEmailDelivery
  def self.call(delivery_id:, at: Time.current, transport: nil)
    new(delivery_id:, at:, transport:).call
  end

  def initialize(delivery_id:, at:, transport:)
    @delivery_id = delivery_id
    @at = at
    @transport = transport
    @claim_token = SecureRandom.uuid
  end

  def call
    return unless find_delivery

    return unless (delivery = claim_delivery)

    unless ReminderDeliveryReconciler.current?(delivery, at:)
      cancel_delivery(delivery)
      return
    end

    result = transport.deliver(message: message_for(delivery), delivery_id: delivery_identifier(delivery))
    mark_delivered(delivery, result)
  rescue MailTransports::DeliveryError => error
    mark_failed(delivery)
    Rails.logger.error("Reminder email delivery failed id=#{delivery_id} error=#{error.class}")
    raise
  rescue StandardError => error
    mark_failed(delivery)
    Rails.logger.error("Reminder email delivery failed id=#{delivery_id} error=#{error.class}")
    raise
  end

  private

  attr_reader :delivery_id, :at, :claim_token

  def find_delivery
    @delivery ||= ReminderDelivery.find_by(id: delivery_id)
  end

  def claim_delivery
    ReminderDelivery.transaction do
      delivery = ReminderDelivery.where(
        id: delivery_id,
        channel: ReminderDelivery::EMAIL_CHANNEL,
        status: [ ReminderDelivery::PENDING_STATUS, ReminderDelivery::FAILED_STATUS ]
      ).lock.first
      next unless delivery
      next if delivery.claimed_at && delivery.claimed_at >= at - claim_timeout

      if delivery.attempts >= retry_attempts
        finalize_exhausted_claim(delivery)
        next
      end

      delivery.update!(claimed_at: at, claim_token:, attempts: delivery.attempts + 1)
      delivery
    end
  end

  def message_for(delivery)
    source = delivery.source
    case source
    when Person
      ReminderMailer.with(delivery:).keep_in_touch
    when Entry::Birthday
      ReminderMailer.with(delivery:).birthday
    when EntryReminder
      if source.entry.is_a?(Entry::Date)
        ReminderMailer.with(delivery:).significant_date
      else
        raise MailTransports::DeliveryError, "Reminder source is not email-eligible"
      end
    else
      raise MailTransports::DeliveryError, "Reminder source is unavailable"
    end
  end

  def transport
    @transport ||= MailTransports.fetch(Rails.application.config.x.reminder_mail_transport)
  end

  def delivery_identifier(delivery)
    "reminder-delivery/#{delivery.id}"
  end

  def mark_delivered(delivery, result)
    update_claimed_delivery(delivery,
      status: ReminderDelivery::DELIVERED_STATUS,
      delivered_at: at,
      failed_at: nil,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at
    )
    result
  end

  def cancel_delivery(delivery)
    update_claimed_delivery(delivery,
      status: ReminderDelivery::CANCELED_STATUS,
      canceled_at: at,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at)
  end

  def mark_failed(delivery)
    return unless delivery

    update_claimed_delivery(delivery,
      status: ReminderDelivery::FAILED_STATUS,
      failed_at: at,
      claimed_at: nil,
      claim_token: nil,
      updated_at: at)
  end

  def update_claimed_delivery(delivery, attributes)
    ReminderDelivery.where(id: delivery.id, claim_token:).update_all(attributes)
  end

  def finalize_exhausted_claim(delivery)
    return unless delivery.status == ReminderDelivery::PENDING_STATUS && delivery.claimed_at

    delivery.update!(
      status: ReminderDelivery::FAILED_STATUS,
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
