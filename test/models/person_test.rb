require "test_helper"

# == Schema Information
#
# Table name: people
#
#  id          :integer          not null, primary key
#  archived_at :datetime
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :integer
#  user_id     :integer          not null
#
# Indexes
#
#  index_people_on_category_id       (category_id)
#  index_people_on_user_id_and_archived_at  (user_id,archived_at)
#  index_people_on_user_id           (user_id)
#  index_people_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  category_id  (category_id => categories.id) ON DELETE => nullify
#  user_id      (user_id => users.id)
#
class PersonTest < ActiveSupport::TestCase
  test "Person uses the people table through the canonical user association" do
    person = users(:one).people.find(people(:ada).id)

    assert_instance_of Person, person
    assert_equal "people", Person.table_name
    assert_equal users(:one), person.user
  end

  test "Person owns records through person foreign keys" do
    person = users(:one).people.create!(name: "Katherine Johnson")
    entry = person.entries.create!(type: "Entry::Note", content: { body: "Mathematician" })
    interaction = person.interactions.create!(occurred_on: Date.current)
    setting = person.create_keep_in_touch_setting!(cadence: "monthly", enabled_on: Date.current)

    assert_equal person.id, entry.person_id
    assert_equal person.id, interaction.person_id
    assert_equal person.id, setting.person_id
  end

  test "Person persistence keeps portable foreign keys and named indexes" do
    connection = Person.connection
    dependent_tables = %i[entries interactions keep_in_touch_settings]

    dependent_tables.each do |table|
      foreign_key = connection.foreign_keys(table).find { _1.to_table == "people" }
      assert_equal "person_id", foreign_key.column
    end

    assert connection.indexes(:people).any? { _1.name == "index_people_on_user_id_and_slug" && _1.unique }
    assert connection.indexes(:people).any? do |index|
      index.name == "index_people_on_user_id_and_archived_at" && index.columns == %w[user_id archived_at]
    end
    assert connection.check_constraints(:people).any? { _1.name == "people_name_is_within_maximum_length" }
  end

  test "Person can be archived and restored" do
    person = people(:ada)
    archived_at = Time.zone.parse("2026-08-27 12:00:00")

    person.archive!(at: archived_at)

    assert_predicate person, :archived?
    assert_equal archived_at, person.archived_at
    assert_includes users(:one).people.archived, person
    assert_not_includes users(:one).people.active, person

    person.restore!

    assert_not_predicate person, :archived?
    assert_nil person.archived_at
    assert_includes users(:one).people.active, person
    assert_not_includes users(:one).people.archived, person
  end

  test "archiving preserves a person's associated information" do
    person = users(:one).people.create!(name: "Katherine Johnson")
    entry = person.entries.create!(type: "Entry::Note", content: { body: "Mathematician" })
    interaction = person.interactions.create!(occurred_on: Date.current)
    setting = person.create_keep_in_touch_setting!(cadence: "monthly", enabled_on: Date.current)

    assert_no_difference [ "Entry.count", "Interaction.count", "KeepInTouchSetting.count" ] do
      person.archive!
    end

    assert_equal [ entry ], person.entries.reload
    assert_equal [ interaction ], person.interactions.reload
    assert_equal setting, person.keep_in_touch_setting.reload
  end

  test "person names have a portable maximum length" do
    person = users(:one).people.new(name: "a" * (Klivka::STRING_MAX_LENGTH + 1))

    assert_not person.valid?
    assert person.errors.added?(:name, :too_long, count: Klivka::STRING_MAX_LENGTH)
  end

  test "category assignment is optional" do
    person = users(:one).people.create!(name: "Mary Jackson")

    assert_nil person.category
  end

  test "person can use a category owned by the same user" do
    person = users(:one).people.create!(name: "Mary Jackson", category: categories(:family))

    assert_equal categories(:family), person.category
  end

  test "person cannot use another user's category" do
    person = users(:one).people.new(name: "Mary Jackson", category: categories(:family_for_user_two))

    assert_not person.valid?
    assert person.errors.added?(:category, :invalid)
  end

  test "slug regenerates when name changes" do
    person = users(:one).people.create!(name: "Marta Rodriguez")
    assert_equal "marta-rodriguez", person.slug

    person.update!(name: "Marta García")
    assert_equal "marta-garcia", person.slug
  end

  test "slug does not change when other attributes change" do
    person = users(:one).people.create!(name: "Ada Byron")
    original_slug = person.slug

    person.touch
    assert_equal original_slug, person.reload.slug
  end

  test "collision appends uuid fallback scoped per user" do
    first = users(:one).people.create!(name: "María López")
    duplicate = users(:one).people.create!(name: "María López")

    assert_equal "maria-lopez", first.slug
    assert_match(/\Amaria-lopez-[0-9a-f\-]{36}\z/, duplicate.slug)
  end

  test "two users can each have a person with the same slug" do
    users(:one).people.create!(name: "María López")
    users(:two).people.create!(name: "María López")

    assert_equal "maria-lopez", users(:one).people.last.slug
    assert_equal "maria-lopez", users(:two).people.last.slug
  end
end
