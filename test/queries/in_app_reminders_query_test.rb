require "test_helper"

class InAppRemindersQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @at = Time.utc(2026, 8, 8, 12)
    @user.update!(
      contact_reminder_cadence: "weekly",
      contact_reminders_enabled_on: Date.new(2026, 8, 1),
      birthday_reminder_lead_value: 30,
      birthday_reminder_lead_unit: "days"
    )
  end

  test "groups due in-app work by reminder type in chronological order" do
    contact = create_delivery(people(:grace), reminder_on: Date.new(2026, 8, 8))
    birthday = create_delivery(
      entries(:ada_birthday),
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
    date_entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7), label: "Anniversary")
    date_reminder = date_entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: "one_time")
    date_delivery = create_delivery(
      date_reminder,
      reminder_on: Date.new(2026, 8, 8),
      occurrence_on: Date.new(2026, 9, 7)
    )

    result = InAppRemindersQuery.call(user: @user, at: Time.utc(2026, 11, 10, 12))

    assert_equal [ contact ], result.contacts
    assert_equal [ birthday ], result.birthdays
    assert_equal [ date_delivery ], result.dates
    assert_predicate result, :any?
  end

  test "orders reminders deterministically within each group" do
    later = create_due_contact(name: "Ada Later", reminder_on: Date.new(2026, 8, 8))
    zeta = create_due_contact(name: "Zeta", reminder_on: Date.new(2026, 8, 7))
    alpha = create_due_contact(name: "Alpha", reminder_on: Date.new(2026, 8, 7))

    result = InAppRemindersQuery.call(user: @user, at: @at)

    assert_equal [ alpha, zeta, later ], result.contacts
  end

  test "excludes future, email, completed, and another account's work" do
    create_delivery(people(:ada), reminder_on: Date.new(2026, 8, 9))
    create_delivery(people(:grace), channel: ReminderDelivery::EMAIL_CHANNEL)
    create_delivery(people(:ada), reminder_on: Date.new(2026, 8, 7), status: ReminderDelivery::DELIVERED_STATUS)

    other_person = users(:two).people.create!(name: "Other account")
    other_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    create_delivery(other_person, user: users(:two))

    result = InAppRemindersQuery.call(user: @user, at: @at)

    assert_not_predicate result, :any?
  end

  test "reconciles stale in-app work before returning results" do
    stale = create_delivery(people(:ada))
    current = create_delivery(people(:grace))
    people(:ada).interactions.create!(occurred_on: Date.new(2026, 8, 8))

    result = InAppRemindersQuery.call(user: @user, at: @at)

    assert_equal [ current ], result.contacts
    assert_equal ReminderDelivery::CANCELED_STATUS, stale.reload.status
  end

  test "actionable presence uses the same reconciled in-app scope" do
    delivery = create_delivery(people(:ada))

    assert InAppRemindersQuery.actionable?(user: @user, at: @at)

    @user.update!(reminder_in_app_enabled: false)

    assert_not InAppRemindersQuery.actionable?(user: @user, at: @at)
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  private

  def create_due_contact(name:, reminder_on:)
    person = @user.people.create!(name:)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: reminder_on - 7.days)
    create_delivery(person, reminder_on:)
  end

  def create_delivery(source, user: @user, channel: ReminderDelivery::IN_APP_CHANNEL,
    reminder_on: Date.new(2026, 8, 8), occurrence_on: reminder_on, status: ReminderDelivery::PENDING_STATUS)
    ReminderDelivery.create!(user:, source:, channel:, reminder_on:, occurrence_on:, status:)
  end
end
