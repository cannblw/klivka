require "test_helper"

# == Schema Information
#
# Table name: interactions
#
#  id             :integer          not null, primary key
#  contact_method :string
#  note           :text
#  occurred_at    :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  friend_id      :integer          not null
#
# Indexes
#
#  index_interactions_on_friend_id                  (friend_id)
#  index_interactions_on_friend_id_and_occurred_at  (friend_id,occurred_at)
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class InteractionTest < ActiveSupport::TestCase
  test "requires an occurrence time" do
    interaction = Interaction.new(friend: friends(:ada))

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:occurred_at, :blank)
  end

  test "allows an interaction with only an occurrence time" do
    interaction = Interaction.new(friend: friends(:ada), occurred_at: 1.hour.ago)

    assert_predicate interaction, :valid?
  end

  test "normalizes optional method and note" do
    interaction = Interaction.new(
      friend: friends(:ada),
      occurred_at: 1.hour.ago,
      contact_method: "  call ",
      note: "  Discussed the trip  "
    )

    assert_predicate interaction, :valid?
    assert_equal "call", interaction.contact_method
    assert_equal "Discussed the trip", interaction.note
  end

  test "allows the supported contact methods and no method" do
    Interaction::CONTACT_METHODS.each do |contact_method|
      assert_predicate Interaction.new(friend: friends(:ada), occurred_at: 1.hour.ago, contact_method: contact_method), :valid?
    end

    assert_predicate Interaction.new(friend: friends(:ada), occurred_at: 1.hour.ago, contact_method: nil), :valid?
  end

  test "rejects an unsupported contact method" do
    interaction = Interaction.new(friend: friends(:ada), occurred_at: 1.hour.ago, contact_method: "sales")

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:contact_method, :inclusion)
  end

  test "rejects a future occurrence time" do
    interaction = Interaction.new(friend: friends(:ada), occurred_at: 1.minute.from_now)

    assert_not interaction.valid?
    assert interaction.errors.of_kind?(:occurred_at, :future)
  end

  test "orders recent interactions by occurrence time and id" do
    older = Interaction.create!(friend: friends(:ada), occurred_at: 2.days.ago)
    newer = Interaction.create!(friend: friends(:ada), occurred_at: 1.day.ago)

    assert_equal [ newer, older ], friends(:ada).interactions.recent.to_a
  end

  test "destroying a friend destroys its interactions" do
    friend = Friend.create!(name: "Interaction Friend", user: users(:one))
    friend.interactions.create!(occurred_at: 1.hour.ago)

    assert_difference "Interaction.count", -1 do
      friend.destroy!
    end
  end

  test "database rejects an unsupported contact method" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Interaction.insert_all!([ {
        friend_id: friends(:ada).id,
        occurred_at: timestamp,
        contact_method: "sales",
        created_at: timestamp,
        updated_at: timestamp
      } ])
    end
  end
end
