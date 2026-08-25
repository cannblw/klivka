require "test_helper"

# == Schema Information
#
# Table name: entry_reminders
#
#  id         :integer          not null, primary key
#  lead_unit  :string           not null
#  lead_value :integer          not null
#  recurrence :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  entry_id   :integer          not null
#
# Indexes
#
#  index_entry_reminders_on_entry_id  (entry_id) UNIQUE
#
# Foreign Keys
#
#  entry_id  (entry_id => entries.id) ON DELETE => cascade
#
class EntryReminderTest < ActiveSupport::TestCase
  test "date entries support reminders except for known exclusions" do
    friend = friends(:ada)
    birthday = entries(:ada_birthday)
    date_entry = Entry::Date.new(friend:, entry_date: Date.new(2020, 8, 10))
    first_met = Entry::FirstMet.new(friend:, entry_date: Date.new(2020, 8, 10))

    assert_not EntryReminder.eligible_entry?(birthday)
    assert EntryReminder.eligible_entry?(date_entry)
    assert_not EntryReminder.eligible_entry?(first_met)
    assert_not EntryReminder.eligible_entry?(entries(:email))
  end

  test "a new reminder uses the account default lead time" do
    user = users(:one)
    user.update!(default_reminder_lead_value: 1, default_reminder_lead_unit: "days")
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))

    reminder = entry.build_entry_reminder

    assert_equal 1, reminder.lead_value
    assert_equal "days", reminder.lead_unit
    assert_equal EntryReminder::ONE_TIME_RECURRENCE, reminder.recurrence
  end

  test "different entries can use different reminder lead times" do
    friend = users(:one).friends.create!(name: "Different reminder times")
    recurring_date = Entry::Date.create!(friend:, entry_date: Date.new(1990, 4, 10))
    anniversary = Entry::Date.create!(friend:, entry_date: Date.new(2018, 9, 2), content: { label: "Wedding anniversary" })

    recurring_date.create_entry_reminder!(lead_value: 1, lead_unit: "months", recurrence: EntryReminder::YEARLY_RECURRENCE)
    anniversary.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: EntryReminder::YEARLY_RECURRENCE)

    assert_equal 30, recurring_date.entry_reminder.lead_days
    assert_equal 1, anniversary.entry_reminder.lead_days
  end

  test "a new reminder preserves an explicitly chosen lead time" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))

    reminder = entry.build_entry_reminder(lead_value: 2, lead_unit: "years")

    assert_equal 2, reminder.lead_value
    assert_equal "years", reminder.lead_unit
  end

  test "a date reminder calculates its own lead time" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 2, lead_unit: "months")

    assert_equal 60, reminder.lead_days
  end

  test "a recurring date reminder repeats yearly" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(
      lead_value: 1,
      lead_unit: "days",
      recurrence: EntryReminder::YEARLY_RECURRENCE
    )

    assert_predicate reminder, :yearly?
  end

  test "a valid stored lead value can normalize beyond the database integer range" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = EntryReminder.new(entry:, lead_value: 5_883_517, lead_unit: "years")

    assert_predicate reminder, :valid?
    assert_equal 2_147_483_705, reminder.lead_days
  end

  test "a reminder uses fixed day counts for month and year lead units" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 3, 1))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "years", recurrence: EntryReminder::YEARLY_RECURRENCE)

    assert_equal 365, reminder.lead_days
    assert_equal Date.new(2027, 3, 2), reminder.reminder_on(year: 2028)

    reminder.update!(lead_value: 1, lead_unit: "months")
    assert_equal 30, reminder.lead_days
    assert_equal Date.new(2028, 1, 31), reminder.reminder_on(year: 2028)
  end

  test "a reminder returns the next reminder date on or after an account local date" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: EntryReminder::YEARLY_RECURRENCE)

    assert_equal Date.new(2026, 7, 11), reminder.next_reminder_on(on: Date.new(2026, 7, 11))
    assert_equal Date.new(2027, 7, 11), reminder.next_reminder_on(on: Date.new(2026, 7, 12))
  end

  test "calculating a yearly reminder for one occurrence requires its year" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: EntryReminder::YEARLY_RECURRENCE)

    error = assert_raises(ArgumentError) { reminder.reminder_on }
    assert_equal "year is required for a yearly reminder", error.message
  end

  test "a leap-day reminder follows the date's February 28 occurrence rule" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 2, 29))
    reminder = entry.create_entry_reminder!(lead_value: 0, lead_unit: "days", recurrence: EntryReminder::YEARLY_RECURRENCE)

    assert_equal Date.new(2025, 2, 28), reminder.reminder_on(year: 2025)
    assert_equal Date.new(2026, 2, 28), reminder.next_reminder_on(on: Date.new(2025, 3, 1))
  end

  test "a one-time reminder does not repeat after its reminder date" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2026, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: EntryReminder::ONE_TIME_RECURRENCE)

    assert_equal Date.new(2026, 7, 11), reminder.reminder_on
    assert_equal Date.new(2026, 7, 11), reminder.next_reminder_on(on: Date.new(2026, 7, 11))
    assert_nil reminder.next_reminder_on(on: Date.new(2026, 7, 12))
  end

  test "an entry supports at most one reminder" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    entry.create_entry_reminder!(lead_value: 1, lead_unit: "days")
    duplicate = EntryReminder.new(entry:, lead_value: 1, lead_unit: "days")

    assert_not_predicate duplicate, :valid?
    assert duplicate.errors.of_kind?(:entry, :taken)
  end

  test "a reminder requires an eligible date entry" do
    reminder = EntryReminder.new(entry: entries(:email), lead_value: 1, lead_unit: "days")

    assert_not_predicate reminder, :valid?
    assert reminder.errors.added?(:entry, :ineligible_for_reminders)
  end

  test "a first-meet date does not support reminders" do
    first_met = Entry::FirstMet.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = EntryReminder.new(entry: first_met, lead_value: 1, lead_unit: "days")

    assert_not_predicate reminder, :valid?
    assert reminder.errors.added?(:entry, :ineligible_for_reminders)
  end

  test "a birthday does not support an individual reminder" do
    reminder = EntryReminder.new(entry: entries(:ada_birthday), lead_value: 1, lead_unit: "days")

    assert_not_predicate reminder, :valid?
    assert reminder.errors.added?(:entry, :ineligible_for_reminders)
  end

  test "a reminder validates its lead time" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = EntryReminder.new(entry:, lead_value: -1, lead_unit: "weeks", recurrence: "weekly")

    assert_not_predicate reminder, :valid?
    assert reminder.errors.of_kind?(:lead_value, :greater_than_or_equal_to)
    assert reminder.errors.of_kind?(:lead_unit, :inclusion)
    assert reminder.errors.of_kind?(:recurrence, :inclusion)
  end

  test "the database rejects unsupported reminder lead times" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days")

    assert_raises ActiveRecord::StatementInvalid do
      reminder.update_columns(lead_value: -1, lead_unit: "weeks")
    end
  end

  test "the database rejects an unsupported reminder recurrence" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days")

    assert_raises ActiveRecord::StatementInvalid do
      reminder.update_column(:recurrence, "weekly")
    end
  end
end
