require "test_helper"

# == Schema Information
#
# Table name: keep_in_touch_settings
#
#  id            :integer          not null, primary key
#  cadence       :string           not null
#  enabled_on    :date
#  lock_version  :integer          default(0), not null
#  snoozed_until :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  person_id     :integer          not null
#
# Indexes
#
#  index_keep_in_touch_settings_on_person_id  (person_id) UNIQUE
#
# Foreign Keys
#
#  person_id  (person_id => people.id)
#
class KeepInTouchSettingTest < ActiveSupport::TestCase
  test "is enabled with an enabled date" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "weekly", enabled_on: Date.current)

    assert_predicate setting, :enabled?
  end

  test "is disabled without an enabled date" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "weekly")

    assert_not_predicate setting, :enabled?
    assert_nil setting.next_suggestion_on
  end

  test "validates cadence" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "hourly", enabled_on: Date.current)

    assert_not_predicate setting, :valid?
    assert_predicate setting.errors[:cadence], :present?
  end

  test "does not allow snoozing when disabled" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "weekly", snoozed_until: Date.current + 7.days)

    assert_not_predicate setting, :valid?
    assert_predicate setting.errors[:base], :present?
  end

  test "calculates the first suggestion from the enabled date" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 8), setting.next_suggestion_on
  end

  test "calculates a daily cadence" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "daily", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 2), setting.next_suggestion_on
  end

  test "calculates from the latest interaction when it is newer than the enabled date" do
    person = people(:ada)
    person.interactions.create!(occurred_on: Date.new(2026, 8, 8))
    setting = KeepInTouchSetting.new(person: person, cadence: "biweekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 22), setting.next_suggestion_on
  end

  test "ignores interactions older than the enabled date" do
    person = people(:ada)
    person.interactions.create!(occurred_on: Date.new(2026, 7, 20))
    setting = KeepInTouchSetting.new(person: person, cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 8), setting.next_suggestion_on
  end

  test "uses calendar arithmetic for monthly, quarterly, and yearly cadences" do
    monthly = KeepInTouchSetting.new(person: people(:ada), cadence: "monthly", enabled_on: Date.new(2026, 1, 31))
    quarterly = KeepInTouchSetting.new(person: people(:grace), cadence: "quarterly", enabled_on: Date.new(2026, 11, 30))
    yearly = KeepInTouchSetting.new(person: people(:ada), cadence: "yearly", enabled_on: Date.new(2024, 2, 29))

    assert_equal Date.new(2026, 2, 28), monthly.next_suggestion_on
    assert_equal Date.new(2027, 2, 28), quarterly.next_suggestion_on
    assert_equal Date.new(2025, 2, 28), yearly.next_suggestion_on
  end

  test "uses the snooze date when it is later than the next suggestion" do
    setting = KeepInTouchSetting.new(
      person: people(:ada),
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      snoozed_until: Date.new(2026, 8, 12)
    )

    assert_equal Date.new(2026, 8, 12), setting.next_suggestion_on
    assert_predicate setting, :snoozed?
  end

  test "is not snoozed when its cadence date is later" do
    setting = KeepInTouchSetting.new(
      person: people(:ada),
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      snoozed_until: Date.new(2026, 8, 7)
    )

    assert_not_predicate setting, :snoozed?
  end

  test "is due on or after its next suggestion date" do
    setting = KeepInTouchSetting.new(person: people(:ada), cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_not setting.due?(on: Date.new(2026, 8, 7))
    assert setting.due?(on: Date.new(2026, 8, 8))
    assert setting.due?(on: Date.new(2026, 8, 9))
  end

  test "clears a snooze when the latest interaction is on or after the contact reminder was enabled" do
    person = people(:ada)
    setting = person.create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      snoozed_until: Date.new(2026, 8, 12)
    )
    interaction = person.interactions.create!(occurred_on: Date.new(2026, 8, 8))

    setting.clear_snooze_for_latest_interaction!(interaction)

    assert_nil setting.reload.snoozed_until
  end

  test "keeps a snooze when an interaction from before the contact reminder was enabled is added" do
    person = people(:ada)
    setting = person.create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      snoozed_until: Date.new(2026, 8, 12)
    )
    interaction = person.interactions.create!(occurred_on: Date.new(2026, 7, 31))

    setting.clear_snooze_for_latest_interaction!(interaction)

    assert_equal Date.new(2026, 8, 12), setting.reload.snoozed_until
  end

  test "recalculates from the enabled date after the latest interaction is deleted" do
    person = people(:ada)
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.new(2026, 8, 1))
    interaction = person.interactions.create!(occurred_on: Date.new(2026, 8, 8))

    assert_equal Date.new(2026, 8, 15), setting.next_suggestion_on

    interaction.destroy!

    assert_equal Date.new(2026, 8, 8), setting.next_suggestion_on
  end

  test "destroying a person destroys its keep-in-touch setting" do
    person = people(:ada)
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    assert_difference "KeepInTouchSetting.count", -1 do
      person.destroy!
    end

    assert_not KeepInTouchSetting.exists?(setting.id)
  end
end
