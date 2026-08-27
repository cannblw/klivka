require "test_helper"

class ReminderDeliverySchedulerTest < ActiveSupport::TestCase
  test "records each enabled channel for a due keep-in-touch reminder" do
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))

    assert_equal 2, schedule(users(:one), at: Time.utc(2026, 8, 8, 12))

    deliveries = setting.reminder_deliveries
    assert_equal %w[email in_app], deliveries.order(:channel).pluck(:channel)
    assert_equal [ Date.new(2026, 8, 8) ], deliveries.distinct.pluck(:reminder_on)
  end

  test "records late keep-in-touch work against its original due date" do
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(users(:one), at: Time.utc(2026, 8, 10, 12))

    assert_equal [ Date.new(2026, 8, 8) ], setting.reminder_deliveries.distinct.pluck(:reminder_on)
  end

  test "records only the latest yearly occurrence missed since the previous successful scan" do
    user = users(:one)
    reminder = create_date_reminder(
      person: people(:ada), entry_date: Date.new(2020, 9, 10), lead_value: 30, recurrence: "yearly"
    )
    mark_scanned(user, through: Date.new(2023, 1, 1))

    schedule(user, at: Time.utc(2026, 8, 12, 12))

    assert_equal [ Date.new(2026, 8, 11) ], reminder.reminder_deliveries.distinct.pluck(:reminder_on)
    assert_equal [ Date.new(2026, 9, 10) ], reminder.reminder_deliveries.distinct.pluck(:occurrence_on)
  end

  test "records a missed one-time entry reminder" do
    user = users(:one)
    reminder = create_date_reminder(
      person: people(:ada), entry_date: Date.new(2026, 9, 10), lead_value: 30, recurrence: "one_time"
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
      person: people(:ada), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
    )

    assert_equal 2, schedule(user, at: Time.utc(2026, 8, 12, 16))
    assert_equal 2, reminder.reminder_deliveries.count
  end

  test "uses the account time zone for its authoritative scan date" do
    user = users(:two)
    reminder = create_date_reminder(
      person: people(:bob), entry_date: Date.new(2026, 8, 11), lead_value: 0, recurrence: "one_time"
    )

    schedule(user, at: Time.utc(2026, 8, 11, 22, 30))

    assert_equal 2, reminder.reminder_deliveries.count
    assert_equal Date.new(2026, 8, 11), user.reload.reminders_scanned_through_on
  end

  test "uses the correct local date after a daylight-saving transition" do
    user = users(:one)
    user.update!(time_zone: "Europe/Madrid", reminders_scanned_through_on: Date.new(2026, 3, 28))
    reminder = create_date_reminder(
      person: people(:ada), entry_date: Date.new(2026, 3, 30), lead_value: 0, recurrence: "one_time"
    )

    schedule(user, at: Time.utc(2026, 3, 29, 22, 30))

    assert_equal 2, reminder.reminder_deliveries.count
    assert_equal Date.new(2026, 3, 30), user.reload.reminders_scanned_through_on
  end

  test "schedules a leap-day yearly reminder on its non-leap-year occurrence" do
    user = users(:one)
    user.update!(reminders_scanned_through_on: Date.new(2027, 2, 26))
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2024, 2, 29))
    reminder = entry.create_entry_reminder!(lead_value: 0, lead_unit: "days", recurrence: "yearly")

    schedule(user, at: Time.utc(2027, 2, 28, 12))

    assert_equal [ Date.new(2027, 2, 28) ], reminder.reminder_deliveries.distinct.pluck(:reminder_on)
    assert_equal [ Date.new(2027, 2, 28) ], reminder.reminder_deliveries.distinct.pluck(:occurrence_on)
  end

  test "records each enabled channel for a birthday using the account timing" do
    user = users(:one)
    user.update!(
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2026, 12, 8)
    )

    assert_equal 2, schedule(user, at: Time.utc(2026, 12, 9, 12))

    deliveries = ReminderDelivery.where(source: entries(:ada_birthday))
    assert_equal %w[email in_app], deliveries.order(:channel).pluck(:channel)
    assert_equal [ Date.new(2026, 12, 9) ], deliveries.distinct.pluck(:reminder_on)
    assert_equal [ Date.new(2026, 12, 10) ], deliveries.distinct.pluck(:occurrence_on)
  end

  test "birthday reminders do not create work when globally disabled" do
    user = users(:one)
    user.update!(
      birthday_reminders_enabled: false,
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2026, 12, 8)
    )

    assert_equal 0, schedule(user, at: Time.utc(2026, 12, 9, 12))
    assert_empty ReminderDelivery.where(source: entries(:ada_birthday))
  end

  test "birthday reminders schedule from month and day when the birth year is unknown" do
    user = users(:one)
    person = user.people.create!(name: "Yearless Birthday")
    birthday = Entry::Birthday.create!(
      person:, entry_date: Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, 3, 3), birthday_year_known: false
    )
    user.update!(
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2027, 3, 1)
    )

    schedule(user, at: Time.utc(2027, 3, 2, 12))

    delivery = ReminderDelivery.where(source: birthday).first!
    assert_equal Date.new(2027, 3, 2), delivery.reminder_on
    assert_equal Date.new(2027, 3, 3), delivery.occurrence_on
  end

  test "birthday scheduling observes leap-day birthdays on February 28" do
    user = users(:one)
    person = user.people.create!(name: "Leap Day Person")
    birthday = Entry::Birthday.create!(person:, entry_date: Date.new(2000, 2, 29))
    user.update!(
      birthday_reminder_lead_value: 0,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2027, 2, 27)
    )

    schedule(user, at: Time.utc(2027, 2, 28, 12))

    delivery = ReminderDelivery.where(source: birthday).first!
    assert_equal Date.new(2027, 2, 28), delivery.reminder_on
    assert_equal Date.new(2027, 2, 28), delivery.occurrence_on
  end

  test "birthday scheduling keeps separate work for people sharing a birthday" do
    user = users(:one)
    person = user.people.create!(name: "Same Birthday Person")
    birthday = Entry::Birthday.create!(person:, entry_date: Date.new(1990, 12, 10))
    user.update!(
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2026, 12, 8)
    )

    schedule(user, at: Time.utc(2026, 12, 9, 12))

    assert_equal 2, ReminderDelivery.where(source: entries(:ada_birthday)).count
    assert_equal 2, ReminderDelivery.where(source: birthday).count
  end

  test "birthday scheduling only processes birthdays owned by the requested account" do
    other_person = users(:two).people.create!(name: "Other Account Birthday")
    other_birthday = Entry::Birthday.create!(person: other_person, entry_date: Date.new(1990, 12, 10))
    user = users(:one)
    user.update!(
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days",
      reminders_scanned_through_on: Date.new(2026, 12, 8)
    )

    schedule(user, at: Time.utc(2026, 12, 9, 12))

    assert_equal 2, ReminderDelivery.where(source: entries(:ada_birthday)).count
    assert_empty ReminderDelivery.where(source: other_birthday)
  end

  test "processes only reminders belonging to the requested account" do
    other_setting = create_setting(people(:bob), enabled_on: Date.new(2026, 8, 1))
    own_setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(users(:one), at: Time.utc(2026, 8, 8, 12))

    assert_equal 2, own_setting.reminder_deliveries.count
    assert_empty other_setting.reminder_deliveries
  end

  test "does not schedule any reminder source belonging to an archived person" do
    user = users(:one)
    person = user.people.create!(name: "Archived Person")
    setting = create_setting(person, enabled_on: Date.new(2026, 8, 1))
    date_reminder = create_date_reminder(
      person:, entry_date: Date.new(2026, 8, 8), lead_value: 0, recurrence: "one_time"
    )
    birthday = Entry::Birthday.create!(person:, entry_date: Date.new(1990, 8, 8))
    person.archive!

    schedule(user, at: Time.utc(2026, 8, 8, 12))

    assert_empty setting.reminder_deliveries
    assert_empty date_reminder.reminder_deliveries
    assert_empty ReminderDelivery.where(source: birthday)
  end

  test "records work only for enabled account channels" do
    user = users(:one)
    user.update!(reminder_in_app_enabled: false, reminder_email_enabled: true)
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))

    schedule(user, at: Time.utc(2026, 8, 8, 12))

    assert_equal [ "email" ], setting.reminder_deliveries.pluck(:channel)
  end

  test "records only in-app work for the shared demo account" do
    user = users(:one)
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))

    with_demo_mode(user:) do
      assert_equal 1, schedule(user, at: Time.utc(2026, 8, 8, 12))
    end

    assert_equal [ "in_app" ], setting.reminder_deliveries.pluck(:channel)
  end

  test "same-day rescans reuse existing ledger rows" do
    user = users(:one)
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))
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
    setting = create_setting(people(:ada), enabled_on: Date.new(2026, 8, 1))
    delivery = ReminderDelivery.create!(
      user:, source: setting, channel: "email", status: ReminderDelivery::CANCELED_STATUS,
      reminder_on: Date.new(2026, 8, 8), occurrence_on: Date.new(2026, 8, 7),
      canceled_at: Time.utc(2026, 8, 8, 10)
    )
    user.update!(reminder_email_enabled: true)

    assert_equal 2, schedule(user, at: Time.utc(2026, 8, 8, 12))

    delivery.reload
    assert_equal "pending", delivery.status
    assert_equal Date.new(2026, 8, 8), delivery.occurrence_on
    assert_nil delivery.canceled_at
    assert_equal 2, setting.reminder_deliveries.count
  end

  test "does not advance the checkpoint when scheduling fails" do
    user = users(:one)
    create_date_reminder(
      person: people(:ada), entry_date: Date.new(2026, 8, 11), lead_value: 0, recurrence: "one_time"
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
      person: people(:ada), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
    )
    second_reminder = create_date_reminder(
      person: people(:grace), entry_date: Date.new(2026, 8, 12), lead_value: 0, recurrence: "one_time"
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

  def create_setting(person, enabled_on:)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on:)
  end

  def create_date_reminder(person:, entry_date:, lead_value:, recurrence:)
    entry = Entry::Date.create!(person:, entry_date:)
    entry.create_entry_reminder!(lead_value:, lead_unit: "days", recurrence:)
  end

  def mark_scanned(user, through:)
    user.update!(reminders_scanned_through_on: through)
  end
end
