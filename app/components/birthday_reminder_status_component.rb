class BirthdayReminderStatusComponent < ViewComponent::Base
  def initialize(user:, enable_reminders_link: false)
    @user = user
    @enable_reminders_link = enable_reminders_link
  end

  private

  attr_reader :user, :enable_reminders_link

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
    case status_key
    when :disabled then enable_reminders_link ? :enable_reminders : :settings
    when :no_channels then :enable_channel
    else :settings
    end
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
