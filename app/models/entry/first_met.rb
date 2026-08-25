# == Schema Information
#
# Table name: entries
#
#  id                  :integer          not null, primary key
#  birthday_year_known :boolean
#  content             :json
#  entry_date          :date
#  position            :integer          default(0), not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  friend_id           :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_friend_id                (friend_id)
#  index_entries_on_friend_id_and_position   (friend_id,position)
#  index_entries_on_friend_id_for_birthday   (friend_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_friend_id_for_first_met  (friend_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class Entry::FirstMet < Entry::Date
  self.vcard_import_property = Entry::UNSUPPORTED_VCARD_IMPORT_PROPERTY

  DATE_PRECISIONS = %w[day month year].freeze

  store_accessor :content, :note, :date_precision

  attr_writer :entry_year, :entry_month, :entry_day

  before_validation :normalize_note, :set_entry_date_from_parts, :set_default_date_precision

  validates :friend_id, uniqueness: { message: :one_first_met_per_friend }
  validates :date_precision, inclusion: { in: DATE_PRECISIONS }
  validate :date_parts_are_valid

  def years_ago(on: ::Date.current)
    return nil unless entry_date

    years = on.year - entry_date.year
    return years if date_precision == "year"

    month_has_passed = on.month > entry_date.month
    month_is_current = on.month == entry_date.month
    day_has_passed = date_precision == "month" || on.day >= entry_date.day
    years -= 1 unless month_has_passed || (month_is_current && day_has_passed)
    years
  end

  def entry_year
    submitted_part(:entry_year, entry_date&.year)
  end

  def entry_month
    submitted_part(:entry_month, date_precision == "year" ? nil : entry_date&.month)
  end

  def entry_day
    submitted_part(:entry_day, date_precision == "day" ? entry_date&.day : nil)
  end

  private

  def normalize_note
    self.note = note.to_s.strip.presence if note
  end

  def set_entry_date_from_parts
    return unless date_parts_submitted?

    @invalid_date_parts = false
    year = @entry_year.to_s.strip
    month = @entry_month.to_s.strip
    day = @entry_day.to_s.strip

    if year.blank? || (day.present? && month.blank?)
      @invalid_date_parts = true
      self.entry_date = nil
      return
    end

    self.date_precision = day.present? ? "day" : month.present? ? "month" : "year"
    year_number = Integer(year, 10)
    month_number = month.present? ? Integer(month, 10) : 1
    day_number = day.present? ? Integer(day, 10) : 1
    self.entry_date = ::Date.new(year_number, month_number, day_number)
  rescue ArgumentError, TypeError
    @invalid_date_parts = true
    self.entry_date = nil
  end

  def date_parts_are_valid
    errors.add(:entry_date, :invalid) if @invalid_date_parts
  end

  def set_default_date_precision
    self.date_precision ||= "day" if entry_date.present?
  end

  def date_parts_submitted?
    instance_variable_defined?(:@entry_year) ||
      instance_variable_defined?(:@entry_month) ||
      instance_variable_defined?(:@entry_day)
  end

  def submitted_part(name, fallback)
    instance_variable_defined?("@#{name}") ? instance_variable_get("@#{name}") : fallback
  end
end
