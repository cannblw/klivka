class ReminderScanJob < ApplicationJob
  queue_as :reminders
  limits_concurrency key: ->(user_id, *) { user_id }, duration: Rails.application.config.x.reminder_dispatch_interval

  def perform(user_id, at: Time.current)
    return unless (user = User.find_by(id: user_id))

    ReminderDeliveryScheduler.call(user:, at:)
    ReminderDeliveryReconciler.call(user:, at:)
    ReminderDeliveryDispatchJob.perform_later(user.id, at:)
  end
end
