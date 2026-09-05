# == Schema Information
#
# Table name: keep_in_touch_settings
#
#  id                :integer          not null, primary key
#  cadence           :string           not null
#  enabled_on        :date
#  first_reminder_on :date
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  person_id         :integer          not null
#
# Indexes
#
#  index_keep_in_touch_settings_on_person_id  (person_id) UNIQUE
#
# Foreign Keys
#
#  person_id  (person_id => people.id)
#
class KeepInTouchSetting < ApplicationRecord
  CADENCES = ContactReminder::CADENCES
  DEFAULT_CADENCE = ContactReminder::DEFAULT_CADENCE
  SNOOZE_DAYS = ContactReminder::SNOOZE_DAYS
  LATEST_INTERACTION_UNSPECIFIED = ContactReminder::LATEST_INTERACTION_UNSPECIFIED

  belongs_to :person
  validates :cadence, inclusion: { in: CADENCES }
  validate :reminder_dates_are_consistent

  before_validation :normalize_reminder_dates

  def enabled?
    enabled_on.present?
  end

  def next_suggestion_on(latest_interaction_on: LATEST_INTERACTION_UNSPECIFIED)
    contact_reminder.next_suggestion_on(latest_interaction_on:)
  end

  def due?(on:, latest_interaction_on: LATEST_INTERACTION_UNSPECIFIED)
    contact_reminder.due?(on:, latest_interaction_on:)
  end

  def snoozed?
    contact_reminder.snoozed?
  end

  def enable!(on:, cadence: self.cadence, first_reminder_on: nil)
    transaction do
      self.cadence = cadence
      self.enabled_on = on
      self.first_reminder_on = first_reminder_on || default_first_reminder_on(cadence:, on:)
      save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def change_cadence!(cadence:, on: enabled_on, first_reminder_on: nil)
    enable!(cadence:, on:, first_reminder_on:)
  end

  def snooze!(on:)
    transaction { contact_reminder.snooze!(on:) }
  end

  def disable!
    transaction do
      self.enabled_on = nil
      self.first_reminder_on = nil
      save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def clear_snooze_for_latest_interaction!(interaction)
    transaction { contact_reminder.clear_snooze_for_latest_interaction!(interaction) }
  end

  def contact_reminder
    ContactReminder.new(person:, setting: self)
  end

  private

  def default_first_reminder_on(cadence:, on:)
    ContactReminder.default_first_reminder_on(cadence:, on:) if CADENCES.include?(cadence)
  end

  def normalize_reminder_dates
    self.enabled_on, self.first_reminder_on = ContactReminderSchedule.normalize_dates(
      cadence:, enabled_on:, first_reminder_on:
    )
  end

  def reminder_dates_are_consistent
    return if ContactReminderSchedule.dates_consistent?(cadence:, enabled_on:, first_reminder_on:)

    errors.add(:first_reminder_on, :invalid)
  end
end
