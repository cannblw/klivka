require "test_helper"

class ReminderDeliveryReconcilerTest < ActiveSupport::TestCase
  test "keeps pending inherited contact reminder work that matches the global policy" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    person = user.people.create!(name: "Inherited reminder")
    delivery = create_delivery(person)

    assert_equal 0, reconcile

    assert_equal ReminderDelivery::PENDING_STATUS, delivery.reload.status
  end

  test "cancels inherited contact reminder work when the global policy changes" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    disabled_person = user.people.create!(name: "Globally disabled")
    disabled_delivery = create_delivery(disabled_person, channel: "email")
    user.update!(contact_reminders_enabled_on: nil)

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, disabled_delivery.reload.status

    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    changed_person = user.people.create!(name: "Global cadence changed")
    changed_delivery = create_delivery(changed_person, channel: "in_app")
    user.update!(contact_reminder_cadence: "monthly")

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, changed_delivery.reload.status
  end

  test "cancels inherited contact reminder work after an individual opt-out or snooze" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    opted_out_person = user.people.create!(name: "Opted out")
    opted_out_delivery = create_delivery(opted_out_person, channel: "email")
    ContactReminder.for(opted_out_person, user:).opt_out!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, opted_out_delivery.reload.status

    snoozed_person = user.people.create!(name: "Snoozed")
    snoozed_delivery = create_delivery(snoozed_person, channel: "in_app")
    ContactReminder.for(snoozed_person, user:).snooze!(on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, snoozed_delivery.reload.status
  end

  test "cancels inherited contact reminder work after contact or deletion" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    contacted_person = user.people.create!(name: "Contacted person")
    contacted_delivery = create_delivery(contacted_person, channel: "email")
    contacted_person.interactions.create!(occurred_on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, contacted_delivery.reload.status

    deleted_person = user.people.create!(name: "Deleted person")
    deleted_delivery = create_delivery(deleted_person, channel: "in_app")
    deleted_person.destroy!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, deleted_delivery.reload.status
  end

  test "cancels custom work when removing the override changes the effective cadence" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: Date.new(2026, 8, 1))
    person = user.people.create!(name: "Removed override")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    delivery = create_delivery(person)

    ContactReminder.new(person:, setting:, user:).use_default!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  test "keeps pending work that still matches its current source" do
    setting = create_setting
    delivery = create_delivery(setting.person)

    assert_equal 0, reconcile

    assert_equal "pending", delivery.reload.status
    assert_nil delivery.canceled_at
  end

  test "cancels pending work after contact moves the keep-in-touch suggestion" do
    setting = create_setting
    delivery = create_delivery(setting.person)
    setting.person.interactions.create!(occurred_on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile

    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
    assert_equal Time.utc(2026, 8, 8, 12), delivery.canceled_at
  end

  test "cancels pending work after a cadence is snoozed or disabled" do
    setting = create_setting
    snoozed_delivery = create_delivery(setting.person, channel: "email")
    setting.snooze!(on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, snoozed_delivery.reload.status

    setting.person.update!(contact_reminder_snoozed_until: nil)
    disabled_delivery = create_delivery(setting.person, channel: "in_app")
    setting.disable!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, disabled_delivery.reload.status
  end

  test "cancels pending work after a cadence changes or its source is deleted" do
    setting = create_setting
    changed_delivery = create_delivery(setting.person, channel: "email")
    setting.change_cadence!(cadence: "monthly")

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, changed_delivery.reload.status

    deleted_delivery = create_delivery(setting.person, channel: "in_app", reminder_on: Date.new(2026, 9, 1))
    setting.destroy!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, deleted_delivery.reload.status
  end

  test "cancels pending work when its channel is disabled" do
    setting = create_setting
    delivery = create_delivery(setting.person, channel: "email")
    users(:one).update!(reminder_email_enabled: false)

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  test "cancels pending work for every reminder source belonging to an archived person" do
    person = people(:ada)
    setting = create_setting
    keep_in_touch_delivery = create_delivery(setting.person)
    entry = Entry::Date.create!(person:, entry_date: Date.new(2026, 9, 7))
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: "one_time")
    entry_delivery = create_delivery(reminder, channel: "email", occurrence_on: Date.new(2026, 9, 7))
    birthday_delivery = create_delivery(
      entries(:ada_birthday), reminder_on: Date.new(2026, 11, 10), occurrence_on: Date.new(2026, 12, 10)
    )
    person.archive!

    assert_equal 3, reconcile

    [ keep_in_touch_delivery, entry_delivery, birthday_delivery ].each do |delivery|
      assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
    end
  end

  test "does not revoke a pending delivery while an email worker owns its claim" do
    setting = create_setting
    delivery = create_delivery(setting.person, channel: ReminderDelivery::EMAIL_CHANNEL)
    delivery.update!(claimed_at: Time.utc(2026, 8, 8, 11, 59), claim_token: "email-worker-claim")
    users(:one).update!(reminder_email_enabled: false)

    assert_equal 0, reconcile

    delivery.reload
    assert_equal ReminderDelivery::PENDING_STATUS, delivery.status
    assert_equal "email-worker-claim", delivery.claim_token
  end

  test "cancels demo email work while keeping demo in-app work pending" do
    setting = create_setting
    email_delivery = create_delivery(setting.person, channel: "email")
    in_app_delivery = create_delivery(setting.person, channel: "in_app")

    with_demo_mode(user: users(:one)) do
      assert_equal 1, reconcile
    end

    assert_equal ReminderDelivery::CANCELED_STATUS, email_delivery.reload.status
    assert_equal "pending", in_app_delivery.reload.status
  end

  test "cancels pending work when an entry reminder changes or is deleted" do
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7))
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: "one_time")
    changed_delivery = create_delivery(reminder, occurrence_on: Date.new(2026, 9, 7))
    reminder.update!(lead_value: 29)

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, changed_delivery.reload.status

    deleted_delivery = create_delivery(reminder, channel: "email", reminder_on: Date.new(2026, 8, 9), occurrence_on: Date.new(2026, 9, 7))
    reminder.destroy!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, deleted_delivery.reload.status
  end

  test "keeps a birthday delivery that matches the global preference" do
    user = users(:one)
    user.update!(birthday_reminder_lead_value: 30, birthday_reminder_lead_unit: "days")
    delivery = create_delivery(
      entries(:ada_birthday),
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )

    assert_equal 0, reconcile
    assert_equal ReminderDelivery::PENDING_STATUS, delivery.reload.status
  end

  test "cancels birthday work when global preferences or the birthday change" do
    user = users(:one)
    birthday = entries(:ada_birthday)
    user.update!(birthday_reminder_lead_value: 30, birthday_reminder_lead_unit: "days")
    disabled_delivery = create_delivery(
      birthday,
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
    user.update!(birthday_reminders_enabled: false)

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, disabled_delivery.reload.status

    user.update!(birthday_reminders_enabled: true)
    changed_delivery = create_delivery(
      birthday,
      channel: "email",
      reminder_on: Date.new(2027, 11, 10),
      occurrence_on: Date.new(2027, 12, 10)
    )
    birthday.update!(entry_date: Date.new(1815, 12, 11))

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, changed_delivery.reload.status
  end

  test "cancels birthday work when its birthday source is deleted" do
    user = users(:one)
    birthday = entries(:ada_birthday)
    user.update!(birthday_reminder_lead_value: 30, birthday_reminder_lead_unit: "days")
    delivery = create_delivery(
      birthday,
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
    birthday.destroy!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  test "does not alter completed delivery history" do
    setting = create_setting
    delivery = create_delivery(setting.person)
    delivery.update!(status: "delivered", delivered_at: Time.utc(2026, 8, 8, 10))
    setting.disable!

    assert_equal 0, reconcile
    assert_equal "delivered", delivery.reload.status
  end

  private

  def create_setting
    people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
  end

  def create_delivery(source, channel: "in_app", reminder_on: Date.new(2026, 8, 8), occurrence_on: reminder_on)
    ReminderDelivery.create!(user: users(:one), source:, channel:, reminder_on:, occurrence_on:)
  end

  def reconcile
    ReminderDeliveryReconciler.call(user: users(:one), at: Time.utc(2026, 8, 8, 12))
  end
end
