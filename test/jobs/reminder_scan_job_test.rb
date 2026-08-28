require "test_helper"

class ReminderScanJobTest < ActiveJob::TestCase
  test "schedules inherited contact reminders without individual settings" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    person = user.people.create!(name: "Inherited reminder")

    ReminderScanJob.perform_now(user.id, at: Time.utc(2026, 8, 8, 12))

    assert_equal 2, person.reminder_deliveries.count
    assert_nil person.keep_in_touch_setting
  end

  test "schedules and reconciles one account on the reminders queue" do
    user = users(:one)
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    ReminderScanJob.perform_now(user.id, at: Time.utc(2026, 8, 8, 12))

    assert_equal "reminders", ReminderScanJob.queue_name
    assert_equal 2, setting.person.reminder_deliveries.count
    assert_equal Date.new(2026, 8, 8), user.reload.reminders_scanned_through_on
  end

  test "serializes overlapping scans for the same account" do
    first_job = ReminderScanJob.new(users(:one).id, at: Time.utc(2026, 8, 8, 12))
    second_job = ReminderScanJob.new(users(:one).id, at: Time.utc(2026, 8, 8, 13))
    other_account_job = ReminderScanJob.new(users(:two).id, at: Time.utc(2026, 8, 8, 12))

    assert_equal first_job.concurrency_key, second_job.concurrency_key
    assert_not_equal first_job.concurrency_key, other_account_job.concurrency_key
    assert_equal 1, ReminderScanJob.concurrency_limit
  end

  test "finishes safely when an account was deleted after dispatch" do
    assert_no_difference "ReminderDelivery.count" do
      ReminderScanJob.perform_now(-1, at: Time.utc(2026, 8, 8, 12))
    end
  end

  test "a retry reuses ledger work created by the first attempt" do
    user = users(:one)
    people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    at = Time.utc(2026, 8, 8, 12)

    ReminderScanJob.perform_now(user.id, at:)

    assert_no_difference "ReminderDelivery.count" do
      ReminderScanJob.perform_now(user.id, at:)
    end
  end
end
