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
class Entry::Note < Entry
end
