class ReminderDeliveryEmailJob < ApplicationJob
  queue_as :reminders
  retry_on MailTransports::DeliveryError,
    attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
    wait: :polynomially_longer

  def perform(delivery_id)
    ReminderDeliveryEmailDelivery.call(delivery_id:)
  end
end
