class ReminderMailerPreview < ActionMailer::Preview
  def keep_in_touch
    ReminderMailer.with(delivery: delivery_for(keep_in_touch_source)).keep_in_touch
  end

  def birthday
    ReminderMailer.with(delivery: delivery_for(birthday_source)).birthday
  end

  def significant_date
    ReminderMailer.with(delivery: delivery_for(significant_date_source)).significant_date
  end

  private

  def delivery_for(source)
    occurrence_on = Date.current + 14.days
    ReminderDelivery.new(
      user: preview_user,
      source:,
      channel: ReminderDelivery::EMAIL_CHANNEL,
      reminder_on: occurrence_on,
      occurrence_on:
    )
  end

  def preview_user
    @preview_user ||= User.find_by!(email_address: Rails.application.config.x.development_seed_email_address)
  end

  def preview_friend
    @preview_friend ||= preview_user.friends.order(:id).first!
  end

  def keep_in_touch_source
    KeepInTouchSetting.new(friend: preview_friend, cadence: KeepInTouchSetting::DEFAULT_CADENCE, enabled_on: Date.current)
  end

  def birthday_source
    birthday = Entry::Birthday.joins(:friend).find_by!(friends: { user_id: preview_user.id })
    EntryReminder.new(entry: birthday)
  end

  def significant_date_source
    entry = Entry::Date.new(
      friend: preview_friend,
      entry_date: Date.current + 14.days,
      content: { "label" => "A date worth remembering" }
    )
    EntryReminder.new(entry: entry)
  end
end
