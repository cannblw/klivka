require "test_helper"

class ContactReminderScheduleTest < ActiveSupport::TestCase
  test "recognizes an explicitly changed submitted schedule" do
    schedule = ContactReminderSchedule.new(
      cadence: "weekly",
      on: Date.new(2026, 8, 30),
      attributes: { "contact_reminder_schedule_changed" => "1", "first_reminder_weekday" => "2" }
    )

    assert_predicate schedule, :changed?
    assert_equal Date.new(2026, 9, 1), schedule.first_reminder_on
  end

  test "uses the cadence default when no calendar selection was submitted" do
    schedule = ContactReminderSchedule.new(cadence: "monthly", on: Date.new(2026, 1, 31))

    assert_not_predicate schedule, :changed?
    assert_equal Date.new(2026, 2, 28), schedule.first_reminder_on
  end

  test "returns no date for an unsupported cadence so the owning model can report its validation error" do
    schedule = ContactReminderSchedule.new(cadence: "hourly", on: Date.new(2026, 8, 30))

    assert_nil schedule.first_reminder_on
  end

  test "rejects an invalid submitted calendar selection" do
    schedule = ContactReminderSchedule.new(
      cadence: "biweekly",
      on: Date.new(2026, 8, 30),
      attributes: { first_reminder_date: "2026-08-30" }
    )

    assert_raises(ContactReminder::InvalidSchedule) { schedule.first_reminder_on }
  end

  test "normalizes enabled and disabled reminder date pairs" do
    assert_equal [ nil, nil ], ContactReminderSchedule.normalize_dates(
      cadence: "weekly", enabled_on: nil, first_reminder_on: Date.new(2026, 9, 1)
    )
    assert_equal [ Date.new(2026, 8, 30), Date.new(2026, 9, 6) ], ContactReminderSchedule.normalize_dates(
      cadence: "weekly", enabled_on: Date.new(2026, 8, 30), first_reminder_on: nil
    )
  end

  test "checks reminder date-pair consistency independently of model error names" do
    assert ContactReminderSchedule.dates_consistent?(cadence: "hourly", enabled_on: nil, first_reminder_on: nil)
    assert ContactReminderSchedule.dates_consistent?(cadence: "weekly", enabled_on: nil, first_reminder_on: nil)
    assert_not ContactReminderSchedule.dates_consistent?(
      cadence: "weekly", enabled_on: Date.new(2026, 8, 30), first_reminder_on: Date.new(2026, 8, 30)
    )
  end
end
