require "test_helper"
require_relative "../../db/seeds/development"

class DevelopmentSeedDataTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "seed-data@example.com", password: "password")
  end

  test "creates a varied set of one hundred friends" do
    DevelopmentSeedData.call(user: @user)

    assert_equal 100, @user.friends.count
    assert_equal 12, @user.friends.left_joins(:entries).where(entries: { id: nil }).count
    assert_equal 50, @user.friends.joins(:entries).where(entries: { type: "Entry::Phone" }).count
    assert_equal 40, @user.friends.joins(:entries).where(entries: { type: "Entry::Note" }).count
    assert_equal 30, @user.friends.joins(:entries).where(entries: { type: "Entry::Birthday" }).count
    assert_equal 32, @user.friends.joins(:entries).where(entries: { type: "Entry::Email" }).count
    assert_equal 152, @user.friends.joins(:entries).count
  end

  test "creates friends for contact action scenarios" do
    DevelopmentSeedData.call(user: @user)

    contact_actions, phone_overflow, email_overflow, email_entry = @user.friends.order(:id).first(4)

    assert_equal 3, contact_actions.entries.where(type: "Entry::Phone").count
    assert_equal 3, contact_actions.entries.where(type: "Entry::Email").count
    assert_equal 3, phone_overflow.entries.where(type: "Entry::Phone").count
    assert_equal 3, email_overflow.entries.where(type: "Entry::Email").count
    email = email_entry.entries.find_by!(type: "Entry::Email")
    assert email.valid?
    assert_equal "Work", email.label
  end

  test "replaces the seed user's friends without changing other accounts" do
    other_user = User.create!(email_address: "other-seed-data@example.com", password: "password")
    other_friend = other_user.friends.create!(name: "Other Friend")

    DevelopmentSeedData.call(user: @user)
    replaced_friend = @user.friends.first
    seeded_email = @user.friends.order(:id).fourth.entries.find_by!(type: "Entry::Email").email
    replaced_friend.update!(name: "Changed Seed Friend")
    @user.friends.create!(name: "Temporary Friend")

    DevelopmentSeedData.call(user: @user)

    assert_equal 100, @user.friends.count
    assert_equal 152, Entry.joins(:friend).where(friends: { user_id: @user.id }).count
    assert_not @user.friends.exists?(name: "Changed Seed Friend")
    assert_not @user.friends.exists?(name: "Temporary Friend")
    assert_equal 3, @user.friends.order(:id).third.entries.where(type: "Entry::Email").count
    assert_equal seeded_email, @user.friends.order(:id).fourth.entries.find_by!(type: "Entry::Email").email
    assert_equal other_friend, other_user.friends.find_by(name: "Other Friend")
  end
end
