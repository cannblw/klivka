require "test_helper"

class ReminderDeliveryReconcilerTest < ActiveSupport::TestCase
  test "keeps pending work that still matches its current source" do
    setting = create_setting
    delivery = create_delivery(setting)

    assert_equal 0, reconcile

    assert_equal "pending", delivery.reload.status
    assert_nil delivery.canceled_at
  end

  test "cancels pending work after contact moves the keep-in-touch suggestion" do
    setting = create_setting
    delivery = create_delivery(setting)
    setting.friend.interactions.create!(occurred_on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile

    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
    assert_equal Time.utc(2026, 8, 8, 12), delivery.canceled_at
  end

  test "cancels pending work after a cadence is snoozed or disabled" do
    setting = create_setting
    snoozed_delivery = create_delivery(setting, channel: "email")
    setting.snooze!(on: Date.new(2026, 8, 8))

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, snoozed_delivery.reload.status

    setting.update!(snoozed_until: nil)
    disabled_delivery = create_delivery(setting, channel: "in_app")
    setting.disable!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, disabled_delivery.reload.status
  end

  test "cancels pending work after a cadence changes or its source is deleted" do
    setting = create_setting
    changed_delivery = create_delivery(setting, channel: "email")
    setting.change_cadence!(cadence: "monthly")

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, changed_delivery.reload.status

    deleted_delivery = create_delivery(setting, channel: "in_app", reminder_on: Date.new(2026, 9, 1))
    setting.destroy!

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, deleted_delivery.reload.status
  end

  test "cancels pending work when its channel is disabled" do
    setting = create_setting
    delivery = create_delivery(setting, channel: "email")
    users(:one).update!(reminder_email_enabled: false)

    assert_equal 1, reconcile
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  test "does not revoke a pending delivery while an email worker owns its claim" do
    setting = create_setting
    delivery = create_delivery(setting, channel: ReminderDelivery::EMAIL_CHANNEL)
    delivery.update!(claimed_at: Time.utc(2026, 8, 8, 11, 59), claim_token: "email-worker-claim")
    users(:one).update!(reminder_email_enabled: false)

    assert_equal 0, reconcile

    delivery.reload
    assert_equal ReminderDelivery::PENDING_STATUS, delivery.status
    assert_equal "email-worker-claim", delivery.claim_token
  end

  test "cancels demo email work while keeping demo in-app work pending" do
    setting = create_setting
    email_delivery = create_delivery(setting, channel: "email")
    in_app_delivery = create_delivery(setting, channel: "in_app")

    with_demo_mode(user: users(:one)) do
      assert_equal 1, reconcile
    end

    assert_equal ReminderDelivery::CANCELED_STATUS, email_delivery.reload.status
    assert_equal "pending", in_app_delivery.reload.status
  end

  test "cancels pending work when an entry reminder changes or is deleted" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2026, 9, 7))
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

  test "does not alter completed delivery history" do
    setting = create_setting
    delivery = create_delivery(setting)
    delivery.update!(status: "delivered", delivered_at: Time.utc(2026, 8, 8, 10))
    setting.disable!

    assert_equal 0, reconcile
    assert_equal "delivered", delivery.reload.status
  end

  private

  def create_setting
    friends(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
  end

  def create_delivery(source, channel: "in_app", reminder_on: Date.new(2026, 8, 8), occurrence_on: reminder_on)
    ReminderDelivery.create!(user: users(:one), source:, channel:, reminder_on:, occurrence_on:)
  end

  def reconcile
    ReminderDeliveryReconciler.call(user: users(:one), at: Time.utc(2026, 8, 8, 12))
  end
end
