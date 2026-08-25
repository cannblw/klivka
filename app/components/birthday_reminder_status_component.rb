class BirthdayReminderStatusComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end

  private

  attr_reader :user

  def status_key
    return :disabled unless user.birthday_reminders_enabled?
    return :no_channels unless delivery_channel_enabled?

    :enabled
  end

  def message
    if status_key == :enabled
      t("birthday_reminder_status.enabled", timing: timing)
    else
      t("birthday_reminder_status.#{status_key}")
    end
  end

  def settings_link_key
    status_key == :no_channels ? :enable_channel : :settings
  end

  def timing
    return t("entries.reminder.timing.same_day") if user.birthday_reminder_lead_value.zero?

    t(
      "entries.reminder.timing.#{user.birthday_reminder_lead_unit}",
      count: user.birthday_reminder_lead_value
    )
  end

  def delivery_channel_enabled?
    ReminderDelivery::CHANNELS.any? { user.reminder_channel_enabled?(_1) }
  end
end
