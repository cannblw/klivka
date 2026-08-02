require "test_helper"
require_relative "../../db/seeds/development"

class DevelopmentSeedDataTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "seed-data@example.com", password: "password")
  end

  test "creates a varied set of one hundred friends" do
    DevelopmentSeedData.call(user: @user)

    assert_equal 100, @user.friends.count
    assert_equal 15, @user.friends.left_joins(:entries).where(entries: { id: nil }).count
    assert_equal 45, @user.friends.joins(:entries).where(entries: { type: "Entry::Phone" }).count
    assert_equal 40, @user.friends.joins(:entries).where(entries: { type: "Entry::Note" }).count
    assert_equal 30, @user.friends.joins(:entries).where(entries: { type: "Entry::Birthday" }).count
    assert_equal 115, @user.friends.joins(:entries).count
  end

  test "replaces the seed user's friends without changing other accounts" do
    other_user = User.create!(email_address: "other-seed-data@example.com", password: "password")
    other_friend = other_user.friends.create!(name: "Other Friend")

    DevelopmentSeedData.call(user: @user)
    replaced_friend = @user.friends.first
    replaced_friend.update!(name: "Changed Seed Friend")
    @user.friends.create!(name: "Temporary Friend")

    DevelopmentSeedData.call(user: @user)

    assert_equal 100, @user.friends.count
    assert_equal 115, Entry.joins(:friend).where(friends: { user_id: @user.id }).count
    assert_not @user.friends.exists?(name: "Changed Seed Friend")
    assert_not @user.friends.exists?(name: "Temporary Friend")
    assert_equal other_friend, other_user.friends.find_by(name: "Other Friend")
  end
end
