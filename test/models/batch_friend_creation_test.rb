require "test_helper"

class BatchFriendCreationTest < ActiveSupport::TestCase
  test "preview normalizes whitespace and ignores blank lines" do
    creation = BatchFriendCreation.preview(
      user: users(:one),
      names: "  Marie   Curie  \n\n  Katherine\tJohnson \n"
    )

    assert_equal [ "Marie Curie", "Katherine Johnson" ], creation.candidates.map(&:name)
    assert creation.candidates.all?(&:selected)
  end

  test "preview identifies existing and repeated names as possible duplicates" do
    creation = BatchFriendCreation.preview(
      user: users(:one),
      names: "Áda Lovelace\nGrace Hopper\ngrace   hopper\nNew Friend"
    )

    assert_equal [ true, true, true, false ], creation.candidates.map(&:duplicate)
  end

  test "preview only compares names with the current user's friends" do
    creation = BatchFriendCreation.preview(user: users(:one), names: friends(:bob).name)

    assert_not creation.candidates.sole.duplicate
  end

  test "save creates selected name-only friends for the current user" do
    creation = BatchFriendCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson\nDorothy Vaughan")
    creation.candidates.second.selected = false

    assert_difference -> { users(:one).friends.count }, 2 do
      assert_no_difference "Entry.count" do
        assert creation.save
      end
    end

    assert_equal [ "Marie Curie", "Dorothy Vaughan" ], creation.created_friends.map(&:name)
    assert_equal 2, creation.selected_count
    assert_equal 1, creation.skipped_count
  end

  test "save accepts a selected possible duplicate" do
    creation = BatchFriendCreation.preview(user: users(:one), names: friends(:ada).name)

    assert_difference -> { users(:one).friends.count }, 1 do
      assert creation.save
    end
  end

  test "save requires at least one selected candidate" do
    creation = BatchFriendCreation.preview(user: users(:one), names: "Marie Curie")
    creation.candidates.sole.selected = false

    assert_no_difference "Friend.count" do
      assert_not creation.save
    end
    assert creation.errors.added?(:candidates, :blank)
  end

  test "save validates every selected name before creating any friends" do
    creation = BatchFriendCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson")
    creation.candidates.second.name = "a" * (Friend::NAME_MAX_LENGTH + 1)

    assert_no_difference "Friend.count" do
      assert_not creation.save
    end
    assert creation.errors.added?(:candidates, :invalid)
    assert creation.candidates.second.errors.any?
  end

  test "save rolls back every friend when persistence fails" do
    creation = BatchFriendCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson")
    persistence_failure = lambda do |friend|
      raise ActiveRecord::RecordInvalid, friend if friend.name == "Katherine Johnson"
    end
    Friend.set_callback(:create, :after, persistence_failure)

    begin
      original_count = Friend.count
      assert_raises(ActiveRecord::RecordInvalid) { creation.save }
      assert_equal original_count, Friend.count
    ensure
      Friend.skip_callback(:create, :after, persistence_failure)
    end
  end
end
