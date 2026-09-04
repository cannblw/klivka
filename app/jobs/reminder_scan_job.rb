class ReminderScanJob < ApplicationJob
  queue_as :reminders
  limits_concurrency key: ->(user_id, *) { user_id }, duration: Rails.application.config.x.reminder_dispatch_interval

  def perform(user_id, at: Time.current)
    AccountOperationLock.with(user_id) do |user|
      ReminderDelivery::Scheduler.call(user:, at:)
      ReminderDelivery::Reconciler.call(user:, at:)
      ReminderDeliveryDispatchJob.perform_later(user.id, at:)
    end
  end
end
