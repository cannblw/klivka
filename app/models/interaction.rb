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
#  friend_id      :integer          not null
#
# Indexes
#
#  index_interactions_on_friend_id                  (friend_id)
#  index_interactions_on_friend_id_and_occurred_on  (friend_id,occurred_on)
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class Interaction < ApplicationRecord
  CONTACT_METHODS = %w[call message video in_person other].freeze

  attr_writer :validation_date

  belongs_to :friend

  validates :occurred_on, presence: true
  validates :contact_method, inclusion: { in: CONTACT_METHODS }, allow_nil: true
  validate :occurred_on_is_not_in_the_future

  before_validation :normalize_optional_fields

  scope :recent, -> { order(occurred_on: :desc, id: :desc) }

  private

  def normalize_optional_fields
    self.contact_method = contact_method.to_s.strip.presence if contact_method
    self.note = note.to_s.strip.presence if note
  end

  def occurred_on_is_not_in_the_future
    return if occurred_on.blank? || occurred_on <= validation_date

    errors.add(:occurred_on, :future)
  end

  def validation_date
    @validation_date || Date.current
  end
end
