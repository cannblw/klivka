require "test_helper"

class ContactReminderTest < ActiveSupport::TestCase
  test "resolves daily and weekly first reminders strictly after today" do
    today = Date.new(2026, 8, 30)

    assert_equal Date.new(2026, 8, 31),
      ContactReminder.resolve_first_reminder_on(cadence: "daily", on: today)
    assert_equal Date.new(2026, 9, 6), ContactReminder.resolve_first_reminder_on(
      cadence: "weekly", on: today, selection: { first_reminder_weekday: "0" }
    )
  end

  test "uses an explicit future date for a biweekly first reminder" do
    assert_equal Date.new(2026, 9, 10), ContactReminder.resolve_first_reminder_on(
      cadence: "biweekly",
      on: Date.new(2026, 8, 30),
      selection: { first_reminder_date: "2026-09-10" }
    )

    assert_raises(ContactReminder::InvalidSchedule) do
      ContactReminder.resolve_first_reminder_on(
        cadence: "biweekly",
        on: Date.new(2026, 8, 30),
        selection: { first_reminder_date: "2026-08-30" }
      )
    end
  end

  test "clamps monthly quarterly and yearly first reminders to valid future dates" do
    today = Date.new(2026, 1, 31)

    assert_equal Date.new(2026, 2, 28), ContactReminder.resolve_first_reminder_on(
      cadence: "monthly", on: today, selection: { first_reminder_day: "31" }
    )
    assert_equal Date.new(2026, 4, 30), ContactReminder.resolve_first_reminder_on(
      cadence: "quarterly", on: today, selection: { first_reminder_month: "4", first_reminder_day: "31" }
    )
    assert_equal Date.new(2028, 2, 29), ContactReminder.resolve_first_reminder_on(
      cadence: "yearly", on: Date.new(2027, 3, 1), selection: { first_reminder_month: "2", first_reminder_day: "29" }
    )
  end

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

  test "uses the selected first reminder before any later interaction" do
    user = users(:one)
    user.update!(
      contact_reminder_cadence: "weekly",
      contact_reminders_enabled_on: Date.new(2026, 8, 1),
      contact_reminder_first_reminder_on: Date.new(2026, 8, 3)
    )
    reminder = ContactReminder.new(person: people(:ada), setting: nil, user:)

    assert_equal Date.new(2026, 8, 3), reminder.next_suggestion_on(latest_interaction_on: nil)
  end

  test "a later interaction replaces the selected first reminder as the cadence anchor" do
    setting = KeepInTouchSetting.new(
      person: people(:ada),
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      first_reminder_on: Date.new(2026, 8, 15)
    )
    reminder = ContactReminder.new(person: people(:ada), setting:)

    assert_equal Date.new(2026, 8, 14),
      reminder.next_suggestion_on(latest_interaction_on: Date.new(2026, 8, 7))
  end

  test "using the default removes an individual setting and snooze" do
    person = people(:ada)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)
    person.update!(contact_reminder_snoozed_until: Date.current + 7.days)
    reminder = ContactReminder.for(person)

    reminder.use_default!

    assert_nil person.reload.keep_in_touch_setting
    assert_nil person.contact_reminder_snoozed_until
    assert_nil reminder.setting
  end

  test "a cadence choice creates an enabled individual override and clears the snooze" do
    person = people(:ada)
    person.update!(contact_reminder_snoozed_until: Date.current + 7.days)
    reminder = ContactReminder.for(person)

    reminder.override!(cadence: "monthly", on: Date.new(2026, 8, 28))

    assert_equal "monthly", reminder.setting.cadence
    assert_equal Date.new(2026, 8, 28), reminder.setting.enabled_on
    assert_equal Date.new(2026, 9, 28), reminder.setting.first_reminder_on
    assert_nil person.reload.contact_reminder_snoozed_until
  end

  test "opting out preserves the effective cadence for later use" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "quarterly", contact_reminders_enabled_on: Date.current)
    person = people(:ada)
    reminder = ContactReminder.for(person, user:)

    reminder.opt_out!

    assert_equal "quarterly", reminder.setting.cadence
    assert_nil reminder.setting.enabled_on
    assert_nil reminder.setting.first_reminder_on
    assert_predicate reminder, :opted_out?
  end
end
