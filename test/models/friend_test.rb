require "test_helper"

# == Schema Information
#
# Table name: friends
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :integer
#  user_id     :integer          not null
#
# Indexes
#
#  index_friends_on_category_id       (category_id)
#  index_friends_on_user_id           (user_id)
#  index_friends_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  category_id  (category_id => categories.id) ON DELETE => nullify
#  user_id      (user_id => users.id)
#
class FriendTest < ActiveSupport::TestCase
  test "friend name has a portable length limit" do
    friend = users(:one).friends.new(name: "a" * (FriendCrm::STRING_MAX_LENGTH + 1))

    assert_not friend.valid?
    assert friend.errors.added?(:name, :too_long, count: FriendCrm::STRING_MAX_LENGTH)
  end

  test "category assignment is optional" do
    friend = users(:one).friends.create!(name: "Mary Jackson")

    assert_nil friend.category
  end

  test "friend can use a category owned by the same user" do
    friend = users(:one).friends.create!(name: "Mary Jackson", category: categories(:family))

    assert_equal categories(:family), friend.category
  end

  test "friend cannot use another user's category" do
    friend = users(:one).friends.new(name: "Mary Jackson", category: categories(:family_for_user_two))

    assert_not friend.valid?
    assert friend.errors.added?(:category, :invalid)
  end

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
