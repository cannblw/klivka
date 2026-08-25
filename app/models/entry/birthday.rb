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
class Entry::Birthday < Entry::Date
  UNKNOWN_YEAR_ANCHOR = 2000

  self.vcard_import_property = :bday

  attr_writer :entry_year, :entry_month, :entry_day, :current_age

  before_validation :set_entry_date_from_parts, :set_default_birthday_year_known

  validates :friend_id, uniqueness: { message: :one_birthday_per_friend }
  validates :birthday_year_known, inclusion: { in: [ true, false ] }
  validate :date_parts_are_valid

  scope :for_month, ->(date = ::Date.current) {
    month = date.month
    where(adapter_sql(
      sqlite: "CAST(strftime('%m', entry_date) AS INTEGER) = ?",
      postgres: "EXTRACT(MONTH FROM entry_date) = ?"
    ), month)
  }

  def age(on: ::Date.current)
    return nil unless entry_date && birthday_year_known?

    years = on.year - entry_date.year
    years -= 1 if occurrence_on(year: on.year) > on
    years
  end

  def entry_year
    submitted_part(:entry_year, birthday_year_known? ? entry_date&.year : nil)
  end

  def entry_month
    submitted_part(:entry_month, entry_date&.month)
  end

  def entry_day
    submitted_part(:entry_day, entry_date&.day)
  end

  def current_age
    submitted_part(:current_age, nil)
  end

  private

  def set_entry_date_from_parts
    return unless date_parts_submitted?

    @invalid_date_parts = false
    year = @entry_year.to_s.strip
    month = @entry_month.to_s.strip
    day = @entry_day.to_s.strip
    age = @current_age.to_s.strip

    if month.blank? || day.blank? || (year.present? && age.present?)
      invalidate_date_parts
      return
    end

    month_number = Integer(month, 10)
    day_number = Integer(day, 10)

    if year.present?
      self.entry_date = ::Date.new(Integer(year, 10), month_number, day_number)
      self.birthday_year_known = true
    elsif age.present?
      age_number = Integer(age, 10)
      raise ArgumentError if age_number.negative?

      occurrence = birthday_occurrence(year: ::Date.current.year, month: month_number, day: day_number)
      birth_year = ::Date.current.year - age_number
      birth_year -= 1 if occurrence > ::Date.current
      raise ArgumentError unless birth_year.positive?

      self.entry_date = ::Date.new(birth_year, month_number, day_number)
      self.birthday_year_known = true
    else
      self.entry_date = ::Date.new(UNKNOWN_YEAR_ANCHOR, month_number, day_number)
      self.birthday_year_known = false
    end
  rescue ArgumentError, TypeError
    invalidate_date_parts
  end

  def set_default_birthday_year_known
    self.birthday_year_known = true if birthday_year_known.nil? && entry_date.present?
  end

  def date_parts_are_valid
    errors.add(:entry_date, :invalid) if @invalid_date_parts
  end

  def birthday_occurrence(year:, month:, day:)
    ::Date.new(year, month, [ day, ::Date.new(year, month, -1).day ].min)
  end

  def invalidate_date_parts
    @invalid_date_parts = true
    self.entry_date = nil
  end

  def date_parts_submitted?
    instance_variable_defined?(:@entry_year) ||
      instance_variable_defined?(:@entry_month) ||
      instance_variable_defined?(:@entry_day) ||
      instance_variable_defined?(:@current_age)
  end

  def submitted_part(name, fallback)
    instance_variable_defined?("@#{name}") ? instance_variable_get("@#{name}") : fallback
  end
end
