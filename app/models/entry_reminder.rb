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
class EntryReminder < ApplicationRecord
  EXCLUDED_DATE_ENTRY_CLASSES = [ Entry::FirstMet ].freeze
  LEAD_UNITS = Rails.application.config.x.reminder_lead_units
  ONE_TIME_RECURRENCE = "one_time".freeze
  YEARLY_RECURRENCE = "yearly".freeze
  RECURRENCES = [ ONE_TIME_RECURRENCE, YEARLY_RECURRENCE ].freeze

  belongs_to :entry
  has_many :reminder_deliveries, as: :source

  # Association-built records need defaults for forms immediately; validation also covers entries assigned after initialization.
  after_initialize :apply_defaults, if: :new_record?
  before_validation :apply_defaults

  validates :entry, uniqueness: true
  validates :lead_value,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: FriendCrm::MAX_INT32 }
  validates :lead_unit, inclusion: { in: LEAD_UNITS.keys }
  validates :recurrence, inclusion: { in: RECURRENCES }
  # Check constraints cannot inspect the associated STI row, so eligibility is enforced at the model boundary.
  validate :validate_entry_eligibility, :validate_birthday_recurrence

  def self.eligible_entry?(entry)
    entry.is_a?(Entry::Date) && EXCLUDED_DATE_ENTRY_CLASSES.none? { entry.is_a?(_1) }
  end

  def self.default_attributes_for(entry)
    account = entry&.friend&.user

    {
      lead_value: account&.default_reminder_lead_value,
      lead_unit: account&.default_reminder_lead_unit,
      recurrence: entry.is_a?(Entry::Birthday) ? YEARLY_RECURRENCE : ONE_TIME_RECURRENCE
    }
  end

  def one_time?
    recurrence == ONE_TIME_RECURRENCE
  end

  def yearly?
    recurrence == YEARLY_RECURRENCE
  end

  def lead_days
    lead_value * LEAD_UNITS.fetch(lead_unit)
  end

  def reminder_on(year: nil)
    raise ArgumentError, "year is required for a yearly reminder" if yearly? && year.nil?

    occurrence = yearly? ? entry.occurrence_on(year:) : entry.entry_date
    occurrence - lead_days
  end

  def next_reminder_on(on:)
    # The caller supplies the account's local date, keeping reminder behavior independent of the server time zone.
    if one_time?
      one_time_reminder_on = reminder_on
      return one_time_reminder_on if one_time_reminder_on >= on

      return
    end

    entry.next_occurrence_on(on: on + lead_days) - lead_days
  end

  private

  def apply_defaults
    defaults = self.class.default_attributes_for(entry)

    self.lead_value = defaults[:lead_value] if lead_value.nil?
    self.lead_unit = defaults[:lead_unit] if lead_unit.nil?
    self.recurrence = defaults[:recurrence] if recurrence.nil?
  end

  def validate_entry_eligibility
    return if self.class.eligible_entry?(entry)

    errors.add(:entry, :ineligible_for_reminders)
  end

  def validate_birthday_recurrence
    return unless entry.is_a?(Entry::Birthday) && !yearly?

    errors.add(:recurrence, :birthday_must_repeat_yearly)
  end
end
