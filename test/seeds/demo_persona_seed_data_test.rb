require "test_helper"

class DemoPersonaSeedDataTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "demo-personas@example.com", password: "password")
    DemoPersonaSeedData.call(user: @user)
  end

  test "creates fifteen detailed fictional personas" do
    assert_equal DemoPersonaSeedData::FRIEND_COUNT, @user.friends.count
    assert_equal DemoPersonaSeedData::PERSONAS.map { |persona| persona.fetch(:name) }, @user.friends.order(:id).pluck(:name)
    assert_operator @user.friends.joins(:entries).where(entries: { type: "Entry::Note" }).count, :>=, 15
    assert_equal 15, @user.friends.joins(:entries).where(entries: { type: "Entry::Birthday" }).count
    assert_equal 15, @user.friends.joins(:entries).where(entries: { type: "Entry::FirstMet" }).count
    assert_equal 15, @user.friends.joins(:entries).where(entries: { type: "Entry::GiftList" }).count
    assert_equal 102, @user.friends.joins(:interactions).count
    assert_equal 22, @user.friends.find_by!(name: "Marcus Chen").interactions.count
    assert_equal 30, @user.friends.find_by!(name: "Sofía Álvarez").interactions.count
    assert_equal 26, @user.friends.find_by!(name: "Claire Dubois").interactions.count
  end

  test "preserves the persona stories and gift ideas as structured entries" do
    anna = @user.friends.find_by!(name: "Anna Roberts")

    assert_includes anna.entries.find_by!(type: "Entry::Note").content.fetch("text"), "Mechanical engineer"
    assert_equal Date.new(2020, 9, 14), anna.entries.find_by!(type: "Entry::FirstMet").entry_date
    assert_equal "Wedding anniversary", anna.entries.find_by!(type: "Entry::Date").label
    gift_list = anna.entries.find_by!(type: "Entry::GiftList")
    assert_equal "Anna's baking shelf", gift_list.title
    assert_equal "Red digital kitchen scale", gift_list.items.second.fetch("text")
  end

  test "uses reserved fictional contact details" do
    @user.friends.includes(:entries).each do |friend|
      email = friend.entries.find { |entry| entry.type == "Entry::Email" }
      phone = friend.entries.find { |entry| entry.type == "Entry::Phone" }

      assert_match(/@example\.com\z/, email.email)
      assert_match(/\A0/, phone.content.fetch("number"))
    end
  end

  test "includes accented Spanish and Polish persona names" do
    assert @user.friends.exists?(name: "Sofía Álvarez")
    assert @user.friends.exists?(name: "Tomás Hernández")
    assert @user.friends.exists?(name: "Elżbieta Wójcik")
    assert @user.friends.exists?(name: "Łukasz Zieliński")
  end

  test "replaces only the demo user's existing records" do
    other_user = User.create!(email_address: "other-demo-personas@example.com", password: "password")
    other_friend = other_user.friends.create!(name: "Unaffected friend")
    @user.friends.create!(name: "Visitor addition")

    DemoPersonaSeedData.call(user: @user)

    assert_equal DemoPersonaSeedData::FRIEND_COUNT, @user.friends.count
    assert_not @user.friends.exists?(name: "Visitor addition")
    assert_equal other_friend, other_user.friends.find_by(name: "Unaffected friend")
  end
end
