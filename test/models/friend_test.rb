require "test_helper"

# == Schema Information
#
# Table name: friends
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_friends_on_user_id           (user_id)
#  index_friends_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class FriendTest < ActiveSupport::TestCase
  test "slug regenerates when name changes" do
    friend = users(:one).friends.create!(name: "Marta Rodriguez")
    assert_equal "marta-rodriguez", friend.slug

    friend.update!(name: "Marta García")
    assert_equal "marta-garcia", friend.slug
  end

  test "slug does not change when other attributes change" do
    friend = users(:one).friends.create!(name: "Ada Byron")
    original_slug = friend.slug

    friend.touch
    assert_equal original_slug, friend.reload.slug
  end

  test "collision appends uuid fallback scoped per user" do
    first = users(:one).friends.create!(name: "María López")
    duplicate = users(:one).friends.create!(name: "María López")

    assert_equal "maria-lopez", first.slug
    assert_match(/\Amaria-lopez-[0-9a-f\-]{36}\z/, duplicate.slug)
  end

  test "two users can each have a friend with the same slug" do
    users(:one).friends.create!(name: "María López")
    users(:two).friends.create!(name: "María López")

    assert_equal "maria-lopez", users(:one).friends.last.slug
    assert_equal "maria-lopez", users(:two).friends.last.slug
  end
end
