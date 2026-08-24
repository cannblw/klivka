# == Schema Information
#
# Table name: vcard_imports
#
#  id                     :integer          not null, primary key
#  candidates             :json             not null
#  expires_at             :datetime         not null
#  rejected_count         :integer          default(0), not null
#  selected_candidate_ids :json             not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer          not null
#
# Indexes
#
#  index_vcard_imports_on_expires_at  (expires_at)
#  index_vcard_imports_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class VcardImport < ApplicationRecord
  belongs_to :user

  attribute :candidates, default: -> { [] }
  attribute :selected_candidate_ids, default: -> { [] }
  attribute :expires_at, default: -> { Rails.application.config.x.vcard_import_preview_lifetime.from_now }

  validates :candidates, presence: true
  validates :rejected_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :expires_at, presence: true
  validates :selected_candidate_ids, presence: true, on: :import
  validate :candidate_payload_is_valid
  validate :selection_is_valid

  scope :expired, -> { where(expires_at: ..Time.current) }

  def expired?
    expires_at? && expires_at <= Time.current
  end

  def duplicate_count
    candidates.count { |candidate| candidate["duplicate"] }
  end

  def unsupported_properties?
    candidates.any? { |candidate| candidate.fetch("unsupported_properties", []).any? }
  end

  private

  def candidate_payload_is_valid
    return errors.add(:candidates, :invalid) unless candidates.is_a?(Array)

    importable_entry_types = Entry.vcard_importable_types.map(&:name)
    candidate_ids = candidates.filter_map do |candidate|
      candidate["id"] if candidate_is_valid?(candidate, importable_entry_types)
    end

    errors.add(:candidates, :invalid) unless candidate_ids.size == candidates.size && candidate_ids.uniq.size == candidate_ids.size
  end

  def candidate_is_valid?(candidate, importable_entry_types)
    candidate.is_a?(Hash) && candidate["id"].is_a?(Integer) &&
      candidate["name"].is_a?(String) && candidate["name"].present? &&
      candidate["entries"].is_a?(Array) && optional_candidate_annotations_are_valid?(candidate) &&
      candidate["entries"].all? do |entry|
        entry.is_a?(Hash) && importable_entry_types.include?(entry["type"])
      end
  end

  def optional_candidate_annotations_are_valid?(candidate)
    [ true, false, nil ].include?(candidate["duplicate"]) &&
      optional_unsupported_properties_are_valid?(candidate["unsupported_properties"])
  end

  def optional_unsupported_properties_are_valid?(properties)
    properties.nil? || properties.is_a?(Array) && properties.all? { |property| property.is_a?(String) && property.present? } &&
      properties.uniq.size == properties.size
  end

  def selection_is_valid
    unless selected_candidate_ids.is_a?(Array) && selected_candidate_ids.all? { |id| id.is_a?(Integer) }
      return errors.add(:selected_candidate_ids, :invalid)
    end

    candidate_ids = if candidates.is_a?(Array)
      candidates.filter_map { |candidate| candidate["id"] if candidate.is_a?(Hash) }
    else
      []
    end
    errors.add(:selected_candidate_ids, :invalid) unless selected_candidate_ids.uniq.size == selected_candidate_ids.size &&
      (selected_candidate_ids - candidate_ids).empty?
  end
end
