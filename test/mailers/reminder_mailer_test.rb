require "test_helper"

class ReminderMailerTest < ActionMailer::TestCase
  test "keep-in-touch email includes localized copy and direct contact links" do
    setting = friends(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(setting, reminder_on: Date.new(2026, 8, 8))

    mail = ReminderMailer.with(delivery:).keep_in_touch

    assert_equal [ "one@example.com" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_equal "A reminder to keep in touch with Ada Lovelace", mail.subject
    assert_includes mail.html_part.body.to_s, 'src="http://localhost:3000/brand/klivka-logo.svg"'
    assert_includes mail.html_part.body.to_s, "Keep in touch with Ada Lovelace"
    assert_includes mail.text_part.body.to_s,
      "http://localhost:3000/friends/ada-lovelace?quick_interaction=today#quick-interaction-dialog"
    assert_includes mail.text_part.body.to_s, "http://localhost:3000/settings"
  end

  test "birthday email uses the account locale and links to the friend" do
    users(:one).update!(locale: "es")
    delivery = create_delivery(entries(:ada_birthday), reminder_on: Date.new(2026, 12, 1), occurrence_on: Date.new(2026, 12, 10))

    mail = ReminderMailer.with(delivery:).birthday

    assert_equal "Se acerca el cumpleaños de Ada Lovelace", mail.subject
    assert_includes mail.html_part.body.to_s, "El cumpleaños de Ada Lovelace"
    assert_includes mail.text_part.body.to_s, "/friends/ada-lovelace"
  end

  test "significant-date email includes its label and localized date" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2026, 9, 7), content: { "label" => "Moving day" })
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    delivery = create_delivery(reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))

    mail = ReminderMailer.with(delivery:).significant_date

    assert_equal "Ada Lovelace: Moving day is coming up", mail.subject
    assert_includes mail.text_part.body.to_s, "Moving day for Ada Lovelace is on"
    assert_includes mail.text_part.body.to_s, "September 07, 2026"
  end

  test "significant-date email uses a localized fallback when the entry has no label" do
    users(:one).update!(locale: "es")
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2026, 9, 7))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    delivery = create_delivery(reminder, reminder_on: Date.new(2026, 9, 6), occurrence_on: Date.new(2026, 9, 7))

    mail = ReminderMailer.with(delivery:).significant_date

    assert_equal "Una fecha importante de Ada Lovelace se acerca", mail.subject
    assert_includes mail.text_part.body.to_s, "Una fecha importante de Ada Lovelace"
  end

  private

  def create_delivery(source, reminder_on:, occurrence_on: reminder_on)
    ReminderDelivery.create!(
      user: users(:one), source:, channel: "email", reminder_on:, occurrence_on:
    )
  end
end
