require "test_helper"

# == Schema Information
#
# Table name: entry_reminders
#
#  id         :integer          not null, primary key
#  lead_unit  :string           not null
#  lead_value :integer          not null
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

    assert EntryReminder.eligible_entry?(birthday)
    assert EntryReminder.eligible_entry?(date_entry)
    assert_not EntryReminder.eligible_entry?(first_met)
    assert_not EntryReminder.eligible_entry?(entries(:email))
  end

  test "a birthday reminder can use its own lead time" do
    reminder = entry_reminders(:ada_birthday)

    assert_equal 1, reminder.lead_value
    assert_equal "months", reminder.lead_unit
    assert_equal 30, reminder.lead_days
  end

  test "a new reminder uses the account default lead time" do
    user = users(:one)
    user.update!(default_reminder_lead_value: 1, default_reminder_lead_unit: "days")
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))

    reminder = entry.build_entry_reminder

    assert_equal 1, reminder.lead_value
    assert_equal "days", reminder.lead_unit
  end

  test "different entries can use different reminder lead times" do
    friend = users(:one).friends.create!(name: "Different reminder times")
    birthday = Entry::Birthday.create!(friend:, entry_date: Date.new(1990, 4, 10))
    anniversary = Entry::Date.create!(friend:, entry_date: Date.new(2018, 9, 2), content: { label: "Wedding anniversary" })

    birthday.create_entry_reminder!(lead_value: 1, lead_unit: "months")
    anniversary.create_entry_reminder!(lead_value: 1, lead_unit: "days")

    assert_equal 30, birthday.entry_reminder.lead_days
    assert_equal 1, anniversary.entry_reminder.lead_days
  end

  test "a new reminder preserves an explicitly chosen lead time" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))

    reminder = entry.build_entry_reminder(lead_value: 2, lead_unit: "years")

    assert_equal 2, reminder.lead_value
    assert_equal "years", reminder.lead_unit
  end

  test "a valid stored lead value can normalize beyond the database integer range" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = EntryReminder.new(entry:, lead_value: 5_883_517, lead_unit: "years")

    assert_predicate reminder, :valid?
    assert_equal 2_147_483_705, reminder.lead_days
  end

  test "an entry supports at most one reminder" do
    duplicate = EntryReminder.new(entry: entries(:ada_birthday), lead_value: 1, lead_unit: "days")

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

  test "a reminder validates its lead time" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))
    reminder = EntryReminder.new(entry:, lead_value: -1, lead_unit: "weeks")

    assert_not_predicate reminder, :valid?
    assert reminder.errors.of_kind?(:lead_value, :greater_than_or_equal_to)
    assert reminder.errors.of_kind?(:lead_unit, :inclusion)
  end

  test "the database rejects unsupported reminder lead times" do
    assert_raises ActiveRecord::StatementInvalid do
      entry_reminders(:ada_birthday).update_columns(lead_value: -1, lead_unit: "weeks")
    end
  end
end
