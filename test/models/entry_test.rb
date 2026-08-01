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

  test "age returns years after birthday has passed this year" do
    travel_to Date.new(2026, 12, 31) do
      assert_equal 211, entries(:ada_birthday).age
    end
  end

  test "age subtracts one before birthday has occurred this year" do
    travel_to Date.new(2026, 7, 28) do
      assert_equal 210, entries(:ada_birthday).age
    end
  end

  test "age is correct on the birthday itself" do
    travel_to Date.new(2026, 12, 10) do
      assert_equal 211, entries(:ada_birthday).age
    end
  end

  test "age returns nil without entry_date" do
    birthday = Entry::Birthday.new(friend: friends(:ada), entry_date: nil)

    assert_nil birthday.age
  end

  test "age accepts an on: parameter" do
    assert_equal 200, entries(:ada_birthday).age(on: Date.new(2015, 12, 10))
  end

  test "for_month defaults to current month" do
    travel_to Date.new(2026, 7, 1) do
      results = Entry::Birthday.for_month
      assert_includes results, entries(:grace_birthday)
      assert_not_includes results, entries(:ada_birthday)
    end
  end

  test "for_month with explicit month returns matching birthdays" do
    results = Entry::Birthday.for_month(Date.new(2026, 12, 1))

    assert_includes results, entries(:ada_birthday)
    assert_not_includes results, entries(:grace_birthday)
  end

  test "for_month returns empty for month with no birthdays" do
    results = Entry::Birthday.for_month(Date.new(2026, 1, 1))

    assert_empty results
  end

  test "friend.entries includes all types" do
    entries = friends(:ada).entries

    assert_equal 2, entries.size
    assert_includes entries.map(&:type), "Entry::Phone"
    assert_includes entries.map(&:type), "Entry::Birthday"
  end

  test "entry changes touch the friend" do
    friend = friends(:ada)
    original_updated_at = friend.reload.updated_at

    travel 1.minute
    entry = friend.entries.create!(type: "Entry::Note", content: { text: "old" })
    assert_operator friend.reload.updated_at, :>, original_updated_at
    created_at = friend.updated_at

    travel 1.minute
    entry.update!(content: { text: "updated" })
    assert_operator friend.reload.updated_at, :>, created_at
    updated_at = friend.updated_at

    travel 1.minute
    entry.destroy!
    assert_operator friend.reload.updated_at, :>, updated_at
  end
end
