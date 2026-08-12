require "test_helper"

class ReminderDeliverySchedulerTest < ActiveSupport::TestCase
  test "records each enabled channel for a due keep-in-touch reminder" do
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))

    assert_equal 2, schedule(users(:one), at: Time.utc(2026, 8, 8, 12))

    deliveries = setting.reminder_deliveries
    assert_equal %w[email in_app], deliveries.order(:channel).pluck(:channel)
    assert_equal [ Date.new(2026, 8, 8) ], deliveries.distinct.pluck(:reminder_on)
  end

  test "records late keep-in-touch work against its original due date" do
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(users(:one), at: Time.utc(2026, 8, 10, 12))

    assert_equal [ Date.new(2026, 8, 8) ], setting.reminder_deliveries.distinct.pluck(:reminder_on)
  end

  test "records only the latest yearly occurrence missed since the previous successful scan" do
    user = users(:one)
    reminder = create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2020, 9, 10), lead_value: 30, recurrence: "yearly"
    )
    mark_scanned(user, through: Date.new(2023, 1, 1))

    schedule(user, at: Time.utc(2026, 8, 12, 12))

    assert_equal [ Date.new(2026, 8, 11) ], reminder.reminder_deliveries.distinct.pluck(:reminder_on)
    assert_equal [ Date.new(2026, 9, 10) ], reminder.reminder_deliveries.distinct.pluck(:occurrence_on)
  end

  test "records a missed one-time entry reminder" do
    user = users(:one)
    reminder = create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2026, 9, 10), lead_value: 30, recurrence: "one_time"
    )
    mark_scanned(user, through: Date.new(2026, 8, 10))

    schedule(user, at: Time.utc(2026, 8, 12, 12))

    assert_equal 2, reminder.reminder_deliveries.count
    assert_equal [ Date.new(2026, 8, 11) ], reminder.reminder_deliveries.distinct.pluck(:reminder_on)
  end

  test "rescans the current date so reminders created later that day are found" do
    user = users(:one)
    schedule(user, at: Time.utc(2026, 8, 12, 8))
    reminder = create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
    )

    assert_equal 2, schedule(user, at: Time.utc(2026, 8, 12, 16))
    assert_equal 2, reminder.reminder_deliveries.count
  end

  test "uses the account time zone for its authoritative scan date" do
    user = users(:two)
    reminder = create_date_reminder(
      friend: friends(:bob), entry_date: Date.new(2026, 8, 11), lead_value: 0, recurrence: "one_time"
    )

    schedule(user, at: Time.utc(2026, 8, 11, 22, 30))

    assert_equal 2, reminder.reminder_deliveries.count
    assert_equal Date.new(2026, 8, 11), user.reload.reminders_scanned_through_on
  end

  test "uses the correct local date after a daylight-saving transition" do
    user = users(:one)
    user.update!(time_zone: "Europe/Madrid", reminders_scanned_through_on: Date.new(2026, 3, 28))
    reminder = create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2026, 3, 30), lead_value: 0, recurrence: "one_time"
    )

    schedule(user, at: Time.utc(2026, 3, 29, 22, 30))

    assert_equal 2, reminder.reminder_deliveries.count
    assert_equal Date.new(2026, 3, 30), user.reload.reminders_scanned_through_on
  end

  test "schedules a leap-day yearly reminder on its non-leap-year occurrence" do
    user = users(:one)
    user.update!(reminders_scanned_through_on: Date.new(2027, 2, 26))
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2024, 2, 29))
    reminder = entry.create_entry_reminder!(lead_value: 0, lead_unit: "days", recurrence: "yearly")

    schedule(user, at: Time.utc(2027, 2, 28, 12))

    assert_equal [ Date.new(2027, 2, 28) ], reminder.reminder_deliveries.distinct.pluck(:reminder_on)
    assert_equal [ Date.new(2027, 2, 28) ], reminder.reminder_deliveries.distinct.pluck(:occurrence_on)
  end

  test "processes only reminders belonging to the requested account" do
    other_setting = create_setting(friends(:bob), enabled_on: Date.new(2026, 8, 1))
    own_setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(users(:one), at: Time.utc(2026, 8, 8, 12))

    assert_equal 2, own_setting.reminder_deliveries.count
    assert_empty other_setting.reminder_deliveries
  end

  test "records work only for enabled account channels" do
    user = users(:one)
    user.update!(reminder_in_app_enabled: false, reminder_email_enabled: true)
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(user, at: Time.utc(2026, 8, 8, 12))

    assert_equal [ "email" ], setting.reminder_deliveries.pluck(:channel)
  end

  test "records only in-app work for the shared demo account" do
    user = users(:one)
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))

    with_demo_mode(user:) do
      assert_equal 1, schedule(user, at: Time.utc(2026, 8, 8, 12))
    end

    assert_equal [ "in_app" ], setting.reminder_deliveries.pluck(:channel)
  end

  test "same-day rescans reuse existing ledger rows" do
    user = users(:one)
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))
    at = Time.utc(2026, 8, 8, 12)

    assert_equal 2, schedule(user, at:)
    assert_no_difference "ReminderDelivery.count" do
      assert_equal 0, schedule(user, at:)
    end
    assert_equal 2, setting.reminder_deliveries.count
  end

  test "a valid reminder can become pending again after its channel is re-enabled" do
    user = users(:one)
    user.update!(reminder_email_enabled: false)
    setting = create_setting(friends(:ada), enabled_on: Date.new(2026, 8, 1))
    delivery = ReminderDelivery.create!(
      user:, source: setting, channel: "email", status: "cancelled",
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 7),
      cancelled_at: Time.utc(2026, 8, 8, 10)
    )
    user.update!(reminder_email_enabled: true)

    assert_equal 2, schedule(user, at: Time.utc(2026, 8, 8, 12))

    delivery.reload
    assert_equal "pending", delivery.status
    assert_equal Date.new(2026, 8, 8), delivery.occurrence_on
    assert_nil delivery.cancelled_at
    assert_equal 2, setting.reminder_deliveries.count
  end

  test "does not advance the checkpoint when scheduling fails" do
    user = users(:one)
    create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2026, 8, 11), lead_value: 0, recurrence: "one_time"
    )
    mark_scanned(user, through: Date.new(2026, 8, 10))
    failing_scheduler = Class.new(ReminderDeliveryScheduler) do
      private

      def record_deliveries(*)
        raise "delivery store unavailable"
      end
    end

    assert_raises(RuntimeError) do
      failing_scheduler.new(user:, at: Time.utc(2026, 8, 12, 12)).call
    end

    assert_equal Date.new(2026, 8, 10), user.reload.reminders_scanned_through_on
  end

  test "an older queued scan cannot move the checkpoint backwards" do
    user = users(:one)
    user.update!(reminders_scanned_through_on: Date.new(2026, 8, 12))

    schedule(user, at: Time.utc(2026, 8, 11, 12))

    assert_equal Date.new(2026, 8, 12), user.reload.reminders_scanned_through_on
  end

  test "processes reminder sources across bounded batches" do
    user = users(:one)
    first_reminder = create_date_reminder(
      friend: friends(:ada), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
    )
    second_reminder = create_date_reminder(
      friend: friends(:grace), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
    )
    scheduler_class = Class.new(ReminderDeliveryScheduler) do
      private

      def batch_size
        1
      end
    end

    scheduler_class.new(user:, at: Time.utc(2026, 8, 12, 12)).call

    assert_equal 2, first_reminder.reminder_deliveries.count
    assert_equal 2, second_reminder.reminder_deliveries.count
    assert_equal Date.new(2026, 8, 12), user.reload.reminders_scanned_through_on
  end

  private

  def schedule(user, at:)
    ReminderDeliveryScheduler.call(user:, at:)
  end

  def create_setting(friend, enabled_on:)
    friend.create_keep_in_touch_setting!(cadence: "weekly", enabled_on:)
  end

  def create_date_reminder(friend:, entry_date:, lead_value:, recurrence:)
    entry = Entry::Date.create!(friend:, entry_date:)
    entry.create_entry_reminder!(lead_value:, lead_unit: "days", recurrence:)
  end

  def mark_scanned(user, through:)
    user.update!(reminders_scanned_through_on: through)
  end
end
