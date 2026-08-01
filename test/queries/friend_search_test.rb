require "test_helper"

class FriendSearchTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "returns all friends alphabetically for a blank query" do
    assert_equal [ "Ada Lovelace", "Grace Hopper" ], FriendSearch.call(@user, "  ").map(&:name)
  end

  test "only searches the given user's friends" do
    Friend.create!(user: users(:two), name: "Bob")

    assert_empty FriendSearch.call(@user, "Bob")
  end

  test "ranks exact names before prefix matches" do
    Friend.create!(user: @user, name: "John")
    Friend.create!(user: @user, name: "Johnny Appleseed")

    assert_equal [ "John", "Johnny Appleseed" ], FriendSearch.call(@user, "john").map(&:name)
  end

  test "matches prefixes on every name token" do
    Friend.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], FriendSearch.call(@user, "smi").map(&:name)
  end

  test "matches substrings within names" do
    assert_equal [ "Ada Lovelace" ], FriendSearch.call(@user, "ovel").map(&:name)
  end

  test "matches initials" do
    Friend.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], FriendSearch.call(@user, "js").map(&:name)
  end

  test "matches names without diacritics" do
    Friend.create!(user: @user, name: "José Álvarez")

    assert_equal [ "José Álvarez" ], FriendSearch.call(@user, "jose").map(&:name)
  end

  test "matches misspellings" do
    Friend.create!(user: @user, name: "Jonathan")

    assert_equal [ "Jonathan" ], FriendSearch.call(@user, "jonatahn").map(&:name)
  end

  test "matches reordered name tokens" do
    Friend.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], FriendSearch.call(@user, "smith john").map(&:name)
  end

  test "does not use fuzzy matching for one-character queries" do
    Friend.create!(user: @user, name: "Zoe")

    assert_empty FriendSearch.call(@user, "q")
  end

  test "rejects weak fuzzy matches" do
    assert_empty FriendSearch.call(@user, "zzzz")
  end

  test "orders equal scores alphabetically" do
    Friend.create!(user: @user, name: "Alicia")
    Friend.create!(user: @user, name: "Alison")

    assert_equal [ "Alicia", "Alison" ], FriendSearch.call(@user, "ali").map(&:name)
  end

  test "limits non-empty searches to the configured maximum" do
    maximum_results = Rails.application.config.x.friend_search_max_results
    (maximum_results + 1).times { |index| Friend.create!(user: @user, name: "Alex #{index}") }

    assert_equal maximum_results, FriendSearch.call(@user, "alex").size
  end
end
