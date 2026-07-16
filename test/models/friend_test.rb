require "test_helper"

# == Schema Information
#
# Table name: friends
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_friends_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class FriendTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
