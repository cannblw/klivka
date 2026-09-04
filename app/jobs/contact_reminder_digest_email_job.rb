class ContactReminderDigestEmailJob < ApplicationJob
  queue_as :reminders
  retry_on MailTransports::DeliveryError,
    attempts: Rails.application.config.x.reminder_delivery_retry_attempts,
    wait: :polynomially_longer

  def perform(digest_id)
    account_id = ContactReminderDigest.where(id: digest_id).pick(:user_id)
    return unless account_id

    failure = nil
    result = AccountOperationLock.with(account_id) do
      ContactReminderDigestEmailDelivery.call(digest_id:)
    rescue StandardError => error
      failure = error
      nil
    end
    raise failure if failure

    result
  end
end
