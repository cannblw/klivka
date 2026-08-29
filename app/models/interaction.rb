# == Schema Information
#
# Table name: interactions
#
#  id                          :integer          not null, primary key
#  contact_method_icon_library :string
#  contact_method_icon_name    :string
#  contact_method_name         :string
#  note                        :text
#  occurred_on                 :date             not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  person_id                   :integer          not null
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
class Interaction < ApplicationRecord
  PRESERVE_CONTACT_METHOD_VALUE = "preserve"

  attr_accessor :contact_method_id
  attr_writer :validation_date

  belongs_to :person

  validates :occurred_on, presence: true
  validates :contact_method_name, length: { maximum: Klivka::STRING_MAX_LENGTH }, allow_nil: true
  validates :contact_method_icon_library, :contact_method_icon_name,
    length: { maximum: Klivka::STRING_MAX_LENGTH }, allow_nil: true
  validate :contact_method_icon_is_complete
  validate :occurred_on_is_not_in_the_future

  before_validation :normalize_optional_fields

  scope :recent, -> { order(occurred_on: :desc, id: :desc) }

  def snapshot_contact_method(contact_method)
    self.contact_method_id = contact_method&.id
    self.contact_method_name = contact_method&.name
    self.contact_method_icon_library = contact_method&.icon_library
    self.contact_method_icon_name = contact_method&.icon_name
  end

  private

  def normalize_optional_fields
    self.contact_method_name = StringNormalizer.call(contact_method_name).presence if contact_method_name
    self.contact_method_icon_library = contact_method_icon_library.to_s.strip.presence if contact_method_icon_library
    self.contact_method_icon_name = contact_method_icon_name.to_s.strip.presence if contact_method_icon_name
    self.note = note.to_s.strip.presence if note
  end

  def contact_method_icon_is_complete
    icon_values = [ contact_method_icon_library, contact_method_icon_name ]
    return if icon_values.all?(&:blank?)
    return if contact_method_name.present? && icon_values.all?(&:present?)

    errors.add(:contact_method_icon_name, :invalid)
  end

  def occurred_on_is_not_in_the_future
    return if occurred_on.blank? || occurred_on <= validation_date

    errors.add(:occurred_on, :future)
  end

  def validation_date
    @validation_date || Date.current
  end
end
