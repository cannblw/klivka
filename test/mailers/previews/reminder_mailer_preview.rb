class ReminderMailerPreview < ActionMailer::Preview
  def keep_in_touch
    reminder(:keep_in_touch, keep_in_touch_source, :en)
  end

  def keep_in_touch_spanish
    reminder(:keep_in_touch, keep_in_touch_source, :es)
  end

  def birthday
    reminder(:birthday, birthday_source, :en)
  end

  def birthday_spanish
    reminder(:birthday, birthday_source, :es)
  end

  def significant_date
    reminder(:significant_date, significant_date_source, :en)
  end

  def significant_date_spanish
    reminder(:significant_date, significant_date_source, :es)
  end

  private

  def reminder(action, source, locale)
    ReminderMailer.with(delivery: delivery_for(source, locale:)).public_send(action)
  end

  def delivery_for(source, locale:)
    occurrence_on = Date.current + 14.days
    ReminderDelivery.new(
      user: preview_user(locale),
      source:,
      channel: ReminderDelivery::EMAIL_CHANNEL,
      reminder_on: occurrence_on,
      occurrence_on:
    )
  end

  def preview_user(locale = nil)
    user = User.find_by!(email_address: Rails.application.config.x.development_seed_email_address)
    user.locale = locale.to_s if locale
    user
  end

  def preview_person
    @preview_person ||= preview_user.people.order(:id).first!
  end

  def keep_in_touch_source
    preview_person
  end

  def birthday_source
    birthday = Entry::Birthday.new(person: preview_person, entry_date: Date.new(1990, 9, 14))
    EntryReminder.new(entry: birthday)
  end

  def significant_date_source
    entry = Entry::Date.new(
      person: preview_person,
      entry_date: Date.current + 14.days,
      content: { "label" => "A date worth remembering" }
    )
    EntryReminder.new(entry: entry)
  end
end
