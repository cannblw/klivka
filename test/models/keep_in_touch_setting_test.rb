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
#  friend_id     :integer          not null
#
# Indexes
#
#  index_keep_in_touch_settings_on_friend_id  (friend_id) UNIQUE
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class KeepInTouchSettingTest < ActiveSupport::TestCase
  test "is enabled with an enabled date" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "weekly", enabled_on: Date.current)

    assert_predicate setting, :enabled?
  end

  test "is disabled without an enabled date" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "weekly")

    assert_not_predicate setting, :enabled?
    assert_nil setting.next_suggestion_on
  end

  test "validates cadence" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "hourly", enabled_on: Date.current)

    assert_not_predicate setting, :valid?
    assert_predicate setting.errors[:cadence], :present?
  end

  test "does not allow snoozing when disabled" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "weekly", snoozed_until: Date.current + 7.days)

    assert_not_predicate setting, :valid?
    assert_predicate setting.errors[:base], :present?
  end

  test "calculates the first suggestion from the enabled date" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 8), setting.next_suggestion_on
  end

  test "calculates a daily cadence" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "daily", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 2), setting.next_suggestion_on
  end

  test "calculates from the latest interaction when it is newer than the enabled date" do
    friend = friends(:ada)
    friend.interactions.create!(occurred_on: Date.new(2026, 8, 8))
    setting = KeepInTouchSetting.new(friend: friend, cadence: "biweekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 22), setting.next_suggestion_on
  end

  test "ignores interactions older than the enabled date" do
    friend = friends(:ada)
    friend.interactions.create!(occurred_on: Date.new(2026, 7, 20))
    setting = KeepInTouchSetting.new(friend: friend, cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_equal Date.new(2026, 8, 8), setting.next_suggestion_on
  end

  test "uses calendar arithmetic for monthly, quarterly, and yearly cadences" do
    monthly = KeepInTouchSetting.new(friend: friends(:ada), cadence: "monthly", enabled_on: Date.new(2026, 1, 31))
    quarterly = KeepInTouchSetting.new(friend: friends(:grace), cadence: "quarterly", enabled_on: Date.new(2026, 11, 30))
    yearly = KeepInTouchSetting.new(friend: friends(:ada), cadence: "yearly", enabled_on: Date.new(2024, 2, 29))

    assert_equal Date.new(2026, 2, 28), monthly.next_suggestion_on
    assert_equal Date.new(2027, 2, 28), quarterly.next_suggestion_on
    assert_equal Date.new(2025, 2, 28), yearly.next_suggestion_on
  end

  test "uses the snooze date when it is later than the next suggestion" do
    setting = KeepInTouchSetting.new(
      friend: friends(:ada),
      cadence: "weekly",
      enabled_on: Date.new(2026, 8, 1),
      snoozed_until: Date.new(2026, 8, 12)
    )

    assert_equal Date.new(2026, 8, 12), setting.next_suggestion_on
  end

  test "is due on or after its next suggestion date" do
    setting = KeepInTouchSetting.new(friend: friends(:ada), cadence: "weekly", enabled_on: Date.new(2026, 8, 1))

    assert_not setting.due?(on: Date.new(2026, 8, 7))
    assert setting.due?(on: Date.new(2026, 8, 8))
    assert setting.due?(on: Date.new(2026, 8, 9))
  end

  test "destroying a friend destroys its keep-in-touch setting" do
    friend = friends(:ada)
    setting = friend.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    assert_difference "KeepInTouchSetting.count", -1 do
      friend.destroy!
    end

    assert_not KeepInTouchSetting.exists?(setting.id)
  end
end
