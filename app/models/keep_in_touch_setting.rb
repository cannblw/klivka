# == Schema Information
#
# Table name: keep_in_touch_settings
#
#  id           :integer          not null, primary key
#  cadence      :string           not null
#  enabled_on   :date
#  lock_version :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  person_id    :integer          not null
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

  def enable!(on:, cadence: self.cadence)
    transaction do
      self.cadence = cadence
      self.enabled_on = on
      save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def change_cadence!(cadence:)
    transaction do
      self.cadence = cadence
      save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def snooze!(on:)
    transaction do
      person.update!(contact_reminder_snoozed_until: on + SNOOZE_DAYS.days)
      touch
    end
  end

  def disable!
    transaction do
      self.enabled_on = nil
      save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def clear_snooze_for_latest_interaction!(interaction)
    return unless enabled? && person.contact_reminder_snoozed_until.present?
    return if interaction.occurred_on < enabled_on
    return unless interaction.occurred_on == person.interactions.maximum(:occurred_on)

    transaction do
      person.update!(contact_reminder_snoozed_until: nil)
      touch
    end
  end

  def contact_reminder
    ContactReminder.new(person:, setting: self)
  end
end
