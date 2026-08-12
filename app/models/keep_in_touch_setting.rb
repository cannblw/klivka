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
  DEFAULT_CADENCE = "weekly"
  SNOOZE_DAYS = 7

  belongs_to :friend
  has_many :reminder_deliveries, as: :source

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

  def snoozed?
    enabled? && snoozed_until.present? && snoozed_until > cadence_date
  end

  def enable!(on:, cadence: self.cadence)
    self.cadence = cadence
    self.enabled_on = on
    self.snoozed_until = nil
    save!
  end

  def change_cadence!(cadence:)
    self.cadence = cadence
    self.snoozed_until = nil
    save!
  end

  def snooze!(on:)
    self.snoozed_until = on + SNOOZE_DAYS.days
    save!
  end

  def disable!
    self.enabled_on = nil
    self.snoozed_until = nil
    save!
  end

  def clear_snooze_for_latest_interaction!(interaction)
    return unless enabled? && snoozed_until.present?
    return if interaction.occurred_on < enabled_on
    return unless interaction.occurred_on == friend.interactions.maximum(:occurred_on)

    update!(snoozed_until: nil)
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

    errors.add(:base, :snooze_requires_enabled_cadence)
  end
end
