require "test_helper"

# == Schema Information
#
# Table name: interactions
#
#  id             :integer          not null, primary key
#  contact_method :string
#  note           :text
#  occurred_on    :date             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  person_id      :integer          not null
#
# Indexes
#
#  index_interactions_on_person_id                  (person_id)
#  index_interactions_on_person_id_and_occurred_on  (person_id,occurred_on)
#
# Foreign Keys
#
#  person_id  (person_id => people.id)
#
class InteractionTest < ActiveSupport::TestCase
  test "requires an occurrence date" do
    interaction = Interaction.new(person: people(:ada))

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:occurred_on, :blank)
  end

  test "allows an interaction with only an occurrence date" do
    interaction = Interaction.new(person: people(:ada), occurred_on: Date.current)

    assert_predicate interaction, :valid?
  end

  test "normalizes optional method and note" do
    interaction = Interaction.new(
      person: people(:ada),
      occurred_on: Date.current,
      contact_method: "  call ",
      note: "  Discussed the trip  "
    )

    assert_predicate interaction, :valid?
    assert_equal "call", interaction.contact_method
    assert_equal "Discussed the trip", interaction.note
  end

  test "allows the supported contact methods and no method" do
    Interaction::CONTACT_METHODS.each do |contact_method|
      assert_predicate Interaction.new(person: people(:ada), occurred_on: Date.current, contact_method: contact_method), :valid?
    end

    assert_predicate Interaction.new(person: people(:ada), occurred_on: Date.current, contact_method: nil), :valid?
  end

  test "rejects an unsupported contact method" do
    interaction = Interaction.new(person: people(:ada), occurred_on: Date.current, contact_method: "sales")

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:contact_method, :inclusion)
  end

  test "rejects a future occurrence date" do
    interaction = Interaction.new(person: people(:ada), occurred_on: Date.tomorrow)

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:occurred_on, :future)
  end

  test "validates against the browser's local date when provided" do
    interaction = Interaction.new(person: people(:ada), occurred_on: Date.tomorrow)
    interaction.validation_date = Date.tomorrow

    assert_predicate interaction, :valid?
  end

  test "orders recent interactions by occurrence time and id" do
    older = Interaction.create!(person: people(:ada), occurred_on: 2.days.ago.to_date)
    newer = Interaction.create!(person: people(:ada), occurred_on: 1.day.ago.to_date)

    assert_equal [ newer, older ], people(:ada).interactions.recent.to_a
  end

  test "destroying a person destroys its interactions" do
    person = Person.create!(name: "Interaction Person", user: users(:one))
    person.interactions.create!(occurred_on: Date.current)

    assert_difference "Interaction.count", -1 do
      person.destroy!
    end
  end

  test "database rejects an unsupported contact method" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Interaction.insert_all!([ {
        person_id: people(:ada).id,
        occurred_on: Date.current,
        contact_method: "sales",
        created_at: timestamp,
        updated_at: timestamp
      } ])
    end
  end
end
