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
class Interaction < ApplicationRecord
  CONTACT_METHODS = %w[call message video in_person other].freeze

  belongs_to :friend

  validates :occurred_at, presence: true
  validates :contact_method, inclusion: { in: CONTACT_METHODS }, allow_nil: true
  validate :occurred_at_is_not_in_the_future

  before_validation :normalize_optional_fields

  scope :recent, -> { order(occurred_at: :desc, id: :desc) }

  private

  def normalize_optional_fields
    self.contact_method = contact_method.to_s.strip.presence if contact_method
    self.note = note.to_s.strip.presence if note
  end

  def occurred_at_is_not_in_the_future
    return if occurred_at.blank? || occurred_at <= Time.current

    errors.add(:occurred_at, :future)
  end
end
