# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  content    :json
#  entry_date :date
#  position   :integer          default(0), not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  friend_id  :integer          not null
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
class Entry::Date < Entry
  store_accessor :content, :label

  before_validation :normalize_label

  validates :entry_date, presence: true

  def occurrence_on(year:)
    return unless entry_date

    # A February 29 date is observed on February 28 in non-leap years so every annual date has one predictable occurrence.
    ::Date.new(year, entry_date.month, [ entry_date.day, ::Date.new(year, entry_date.month, -1).day ].min)
  end

  def leap_day?
    entry_date&.month == 2 && entry_date.day == 29
  end

  def next_occurrence_on(on:)
    occurrence = occurrence_on(year: on.year)
    occurrence >= on ? occurrence : occurrence_on(year: on.year + 1)
  end

  private

  def normalize_label
    self.label = label.to_s.strip.presence if label
  end
end
