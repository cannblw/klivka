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
class KeepInTouchSetting < ApplicationRecord
  CADENCES = %w[daily weekly biweekly monthly quarterly yearly].freeze

  belongs_to :friend

  validates :cadence, inclusion: { in: CADENCES }
  validate :snooze_requires_enabled_setting

  def enabled?
    enabled_on.present?
  end

  def next_suggestion_on
    return unless enabled?

    [ cadence_date, snoozed_until ].compact.max
  end

  def due?(on:)
    next_suggestion_on&.<= on
  end

  private

  def cadence_date
    case cadence
    when "daily" then base_date + 1.day
    when "weekly" then base_date + 7.days
    when "biweekly" then base_date + 14.days
    when "monthly" then base_date.advance(months: 1)
    when "quarterly" then base_date.advance(months: 3)
    when "yearly" then base_date.advance(years: 1)
    end
  end

  def base_date
    [ enabled_on, friend.interactions.maximum(:occurred_on) ].compact.max
  end

  def snooze_requires_enabled_setting
    return if snoozed_until.blank? || enabled?

    errors.add(:snoozed_until, :invalid)
  end
end
