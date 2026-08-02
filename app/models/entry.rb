# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  content    :json
#  entry_date :date
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  friend_id  :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_friend_id                (friend_id)
#  index_entries_on_friend_id_for_birthday   (friend_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_friend_id_for_first_met  (friend_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
# entry_date exists as a dedicated indexed column so date-bearing types (birthdays,
# anniversaries, reminders) are portable-queryable across SQLite and PostgreSQL without
# adapter-specific JSON extraction.
class Entry < ApplicationRecord
  CREATABLE_TYPES = %w[Entry::Phone Entry::Note Entry::Birthday Entry::Date Entry::Email].freeze

  belongs_to :friend, touch: true

  validates :type, presence: true
  validates :entry_date, absence: true, unless: :date_entry?

  def self.creatable_type(type)
    return unless CREATABLE_TYPES.include?(type)

    type.constantize
  end

  private

  def date_entry?
    is_a?(Entry::Date)
  end
end
