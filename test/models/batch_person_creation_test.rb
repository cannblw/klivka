require "test_helper"

class BatchPersonCreationTest < ActiveSupport::TestCase
  test "preview normalizes whitespace and ignores blank lines" do
    creation = BatchPersonCreation.preview(
      user: users(:one),
      names: "  Marie   Curie  \n\n  Katherine\tJohnson \n"
    )

    assert_equal [ "Marie Curie", "Katherine Johnson" ], creation.candidates.map(&:name)
    assert creation.candidates.all?(&:selected)
  end

  test "preview identifies existing and repeated names as possible duplicates" do
    creation = BatchPersonCreation.preview(
      user: users(:one),
      names: "Áda Lovelace\nGrace Hopper\ngrace   hopper\nNew Person"
    )

    assert_equal [ true, true, true, false ], creation.candidates.map(&:duplicate)
  end

  test "preview only compares names with the current user's people" do
    creation = BatchPersonCreation.preview(user: users(:one), names: people(:bob).name)

    assert_not creation.candidates.sole.duplicate
  end

  test "save creates selected name-only people for the current user" do
    creation = BatchPersonCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson\nDorothy Vaughan")
    creation.candidates.second.selected = false

    assert_difference -> { users(:one).people.count }, 2 do
      assert_no_difference "Entry.count" do
        assert creation.save
      end
    end

    assert_equal [ "Marie Curie", "Dorothy Vaughan" ], creation.created_people.map(&:name)
    assert_equal 2, creation.selected_count
    assert_equal 1, creation.skipped_count
  end

  test "save accepts a selected possible duplicate" do
    creation = BatchPersonCreation.preview(user: users(:one), names: people(:ada).name)

    assert_difference -> { users(:one).people.count }, 1 do
      assert creation.save
    end
  end

  test "save requires at least one selected candidate" do
    creation = BatchPersonCreation.preview(user: users(:one), names: "Marie Curie")
    creation.candidates.sole.selected = false

    assert_no_difference "Person.count" do
      assert_not creation.save
    end
    assert creation.errors.added?(:candidates, :blank)
  end

  test "save validates every selected name before creating any people" do
    creation = BatchPersonCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson")
    creation.candidates.second.name = "a" * (Klivka::STRING_MAX_LENGTH + 1)

    assert_no_difference "Person.count" do
      assert_not creation.save
    end
    assert creation.errors.added?(:candidates, :invalid)
    assert creation.candidates.second.errors.any?
  end

  test "save rolls back every person when persistence fails" do
    creation = BatchPersonCreation.preview(user: users(:one), names: "Marie Curie\nKatherine Johnson")
    persistence_failure = lambda do |person|
      raise ActiveRecord::RecordInvalid, person if person.name == "Katherine Johnson"
    end
    Person.set_callback(:create, :after, persistence_failure)

    begin
      original_count = Person.count
      assert_raises(ActiveRecord::RecordInvalid) { creation.save }
      assert_equal original_count, Person.count
    ensure
      Person.skip_callback(:create, :after, persistence_failure)
    end
  end
end
