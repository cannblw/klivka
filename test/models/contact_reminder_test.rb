require "test_helper"

class ContactReminderTest < ActiveSupport::TestCase
  test "is off when neither an individual nor global policy is enabled" do
    reminder = ContactReminder.for(people(:ada))

    assert_not_predicate reminder, :enabled?
    assert_not_predicate reminder, :inherited?
    assert_nil reminder.next_suggestion_on
  end

  test "inherits the global cadence and enable date" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))

    reminder = ContactReminder.for(people(:ada), user:)

    assert_predicate reminder, :enabled?
    assert_predicate reminder, :inherited?
    assert_equal "weekly", reminder.cadence
    assert_equal Date.new(2026, 8, 8), reminder.next_suggestion_on(latest_interaction_on: nil)
  end

  test "an enabled individual setting completely overrides the global cadence" do
    person = people(:ada)
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    setting = person.create_keep_in_touch_setting!(cadence: "monthly", enabled_on: Date.new(2026, 8, 10))

    reminder = ContactReminder.new(person:, setting:, user:)

    assert_predicate reminder, :overridden?
    assert_not_predicate reminder, :inherited?
    assert_equal Date.new(2026, 9, 10), reminder.next_suggestion_on(latest_interaction_on: nil)
  end

  test "a disabled individual setting opts the person out of the global cadence" do
    person = people(:ada)
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    setting = person.create_keep_in_touch_setting!(cadence: "monthly")

    reminder = ContactReminder.new(person:, setting:, user:)

    assert_predicate reminder, :opted_out?
    assert_not_predicate reminder, :enabled?
    assert_nil reminder.next_suggestion_on
  end

  test "uses a person snooze without changing inherited policy" do
    person = people(:ada)
    person.update!(contact_reminder_snoozed_until: Date.new(2026, 8, 12))
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))

    reminder = ContactReminder.new(person:, setting: nil, user:)

    assert_predicate reminder, :inherited?
    assert_predicate reminder, :snoozed?
    assert_equal Date.new(2026, 8, 12), reminder.next_suggestion_on(latest_interaction_on: nil)
  end

  test "calculates an inherited cadence from a newer latest interaction" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "biweekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    reminder = ContactReminder.new(person: people(:ada), setting: nil, user:)

    assert_equal Date.new(2026, 8, 24), reminder.next_suggestion_on(latest_interaction_on: Date.new(2026, 8, 10))
  end
end
