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
class EntryReminder < ApplicationRecord
  EXCLUDED_DATE_ENTRY_CLASSES = [ Entry::FirstMet ].freeze
  LEAD_UNITS = Rails.application.config.x.reminder_lead_units

  belongs_to :entry

  # Association-built records need defaults for forms immediately; validation also covers entries assigned after initialization.
  after_initialize :apply_default_lead, if: :new_record?
  before_validation :apply_default_lead

  validates :entry, uniqueness: true
  validates :lead_value,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: FriendCrm::MAX_INT32 }
  validates :lead_unit, inclusion: { in: LEAD_UNITS.keys }
  # Check constraints cannot inspect the associated STI row, so eligibility is enforced at the model boundary.
  validate :validate_entry_eligibility

  def self.eligible_entry?(entry)
    entry.is_a?(Entry::Date) && EXCLUDED_DATE_ENTRY_CLASSES.none? { entry.is_a?(_1) }
  end

  def lead_days
    lead_value * LEAD_UNITS.fetch(lead_unit)
  end

  private

  def apply_default_lead
    account = entry&.friend&.user
    return unless account

    self.lead_value = account.default_reminder_lead_value if lead_value.nil?
    self.lead_unit = account.default_reminder_lead_unit if lead_unit.nil?
  end

  def validate_entry_eligibility
    return if self.class.eligible_entry?(entry)

    errors.add(:entry, :ineligible_for_reminders)
  end
end
