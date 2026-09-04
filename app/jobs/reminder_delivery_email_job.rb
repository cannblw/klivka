class ReminderDeliveryEmailJob < ApplicationJob
  queue_as :reminders
  retry_on MailTransports::DeliveryError,
    attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
    wait: :polynomially_longer

  def perform(delivery_id)
    account_id = ReminderDelivery.where(id: delivery_id).pick(:user_id)
    return unless account_id

    failure = nil
    result = AccountOperationLock.with(account_id) do
      ReminderDelivery::EmailDelivery.call(delivery_id:)
    rescue StandardError => error
      failure = error
      nil
    end
    raise failure if failure

    result
  end
end
