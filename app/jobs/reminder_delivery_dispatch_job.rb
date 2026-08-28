class ReminderDeliveryDispatchJob < ApplicationJob
  queue_as :reminders

  def perform(user_id, at: Time.current)
    user = User.find_by(id: user_id)
    return unless user

    dispatch_contact_digest(user, at:)

    ReminderDelivery.where(
      user_id: user.id,
      channel: ReminderDelivery::EMAIL_CHANNEL,
      status: ReminderDelivery::PENDING_STATUS
    ).where.not(source_type: Person.polymorphic_name)
      .where(reminder_on: ..user.local_date(at:)).in_batches(of: batch_size) do |batch|
      batch.pluck(:id).each { |delivery_id| ReminderDeliveryEmailJob.perform_later(delivery_id) }
    end
  end

  private

  def dispatch_contact_digest(user, at:)
    digest = ContactReminderDigestBuilder.call(user:, at:)
    return unless digest&.status == ContactReminderDigest::PENDING_STATUS

    ContactReminderDigestEmailJob.perform_later(digest.id)
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end
end
