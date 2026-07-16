# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  content    :json
#  kind       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  friend_id  :integer          not null
#
# Indexes
#
#  index_entries_on_friend_id  (friend_id)
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class Entry < ApplicationRecord
  belongs_to :friend
end
