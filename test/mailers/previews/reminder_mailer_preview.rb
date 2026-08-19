class ReminderMailerPreview < ActionMailer::Preview
  def keep_in_touch
    ReminderMailer.with(delivery: delivery_for("Brittany Klocko", source: :keep_in_touch)).keep_in_touch
  end

  def birthday
    ReminderMailer.with(delivery: delivery_for("Mathew Schumm", source: "Entry::Birthday")).birthday
  end

  def significant_date
    ReminderMailer.with(delivery: delivery_for("Alec Leuschke", source: "Entry::Date")).significant_date
  end

  private

  def delivery_for(friend_name, source:)
    friend = User.find_by!(email_address: Rails.application.config.x.development_seed_email_address)
      .friends.find_by!(name: friend_name)
    source = if source == :keep_in_touch
      friend.keep_in_touch_setting
    else
      friend.entries.find_by!(type: source).entry_reminder
    end
    ReminderDelivery.find_by!(source_type: source.class.polymorphic_name, source_id: source.id, channel: "email")
  end
end
