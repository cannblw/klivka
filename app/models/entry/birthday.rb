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
#  index_entries_on_entry_date  (entry_date)
#  index_entries_on_friend_id   (friend_id)
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class Entry::Birthday < Entry
  validates :entry_date, presence: true
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
