class ContactReminderDigestBuilder
  def self.call(user:, at: Time.current)
    new(user:, at:).call
  end

  def initialize(user:, at:)
    @user = user
    @at = at
  end

  def call
    return if local_time.hour < delivery_hour

    ContactReminderDigest.transaction do
      existing_digest = user.contact_reminder_digests.find_by(delivery_on: local_date)
      return existing_digest if existing_digest
      return unless eligible_deliveries.exists?

      digest = user.contact_reminder_digests.create!(delivery_on: local_date)
      eligible_deliveries.update_all(contact_reminder_digest_id: digest.id, updated_at: at)
      digest
    end
  rescue ActiveRecord::RecordNotUnique
    user.contact_reminder_digests.find_by!(delivery_on: local_date)
  end

  private

  attr_reader :user, :at

  def eligible_deliveries
    user.reminder_deliveries.where(
      contact_reminder_digest_id: nil,
      source_type: Person.polymorphic_name,
      channel: ReminderDelivery::EMAIL_CHANNEL,
      status: ReminderDelivery::PENDING_STATUS,
      reminder_on: ..local_date
    )
  end

  def local_time
    @local_time ||= at.in_time_zone(user.time_zone)
  end

  def local_date
    local_time.to_date
  end

  def delivery_hour
    Rails.application.config.x.contact_reminder_digest_hour
  end
end
