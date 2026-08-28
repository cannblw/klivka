class ContactReminderDigestEmailJob < ApplicationJob
  queue_as :reminders
  retry_on MailTransports::DeliveryError,
    attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
    wait: :polynomially_longer

  def perform(digest_id)
    ContactReminderDigestEmailDelivery.call(digest_id:)
  end
end
