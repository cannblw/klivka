class ReminderSettingsComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end

  private

  attr_reader :user

  def lead_unit_options
    EntryReminder::LEAD_UNITS.keys.map { |unit| [ t("settings.reminders.lead_units.#{unit}"), unit ] }
  end

  def contact_cadence_options
    ContactReminder::CADENCES.map { |cadence| [ t("contact_reminder.cadences.#{cadence}"), cadence ] }
  end

  def delivery_channel_enabled?
    ReminderDelivery::CHANNELS.any? { user.reminder_channel_enabled?(_1) }
  end
end
