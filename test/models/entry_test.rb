require "test_helper"

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
class EntryTest < ActiveSupport::TestCase
  test "instantiates STI subclasses by type" do
    phone = Entry::Phone.new(friend: friends(:ada))
    assert_instance_of Entry::Phone, phone
    assert_equal "Entry::Phone", phone.type
  end

  test "queries return typed objects" do
    assert_instance_of Entry::Phone, entries(:phone)
    assert_instance_of Entry::Note, entries(:note)
    assert_instance_of Entry::Birthday, entries(:ada_birthday)
  end

  test "birthday validates entry_date presence" do
    birthday = Entry::Birthday.new(friend: friends(:ada), entry_date: nil)

    assert_not birthday.valid?
    assert birthday.errors.of_kind?(:entry_date, :blank)
  end

  test "birthday enforces one per friend" do
    duplicate = Entry::Birthday.new(friend: friends(:ada), entry_date: Date.current)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:friend_id, :taken)
    assert_includes duplicate.errors[:friend_id], "already has a birthday"
  end

  test "date validates entry_date presence" do
    date_entry = Entry::Date.new(friend: friends(:ada), entry_date: nil)

    assert_not date_entry.valid?
    assert date_entry.errors.of_kind?(:entry_date, :blank)
  end

  test "friend.entries includes all types" do
    entries = friends(:ada).entries

    assert_equal 2, entries.size
    assert_includes entries.map(&:type), "Entry::Phone"
    assert_includes entries.map(&:type), "Entry::Birthday"
  end
end
