class ReminderScanDispatcherJob < ApplicationJob
  queue_as :background

  def perform(at: Time.current)
    User.in_batches(of: account_batch_size) do |accounts|
      jobs = accounts.ids.map { |user_id| ReminderScanJob.new(user_id, at:) }
      ActiveJob.perform_all_later(jobs)
    end
  end

  private

  def account_batch_size
    Rails.application.config.x.reminder_account_batch_size
  end
end
