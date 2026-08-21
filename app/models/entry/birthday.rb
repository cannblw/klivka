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
class Entry::Birthday < Entry::Date
  self.vcard_import_property = :bday

  validates :friend_id, uniqueness: { message: :one_birthday_per_friend }

  scope :for_month, ->(date = ::Date.current) {
    month = date.month
    where(adapter_sql(
      sqlite: "CAST(strftime('%m', entry_date) AS INTEGER) = ?",
      postgres: "EXTRACT(MONTH FROM entry_date) = ?"
    ), month)
  }

  def age(on: ::Date.current)
    return nil unless entry_date

    years = on.year - entry_date.year
    past = (on.month > entry_date.month) ||
           (on.month == entry_date.month && on.day >= entry_date.day)
    years -= 1 unless past
    years
  end
end
