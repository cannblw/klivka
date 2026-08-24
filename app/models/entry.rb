# == Schema Information
#
# Table name: entries
#
#  id         :integer          not null, primary key
#  content    :json
#  entry_date :date
#  position   :integer          default(0), not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  friend_id  :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_friend_id                (friend_id)
#  index_entries_on_friend_id_and_position   (friend_id,position)
#  index_entries_on_friend_id_for_birthday   (friend_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_friend_id_for_first_met  (friend_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
# entry_date exists as a dedicated indexed column so date-bearing types (birthdays,
# anniversaries, reminders) are portable-queryable across SQLite and PostgreSQL without
# adapter-specific JSON extraction.
class Entry < ApplicationRecord
  CREATABLE_TYPES = %w[
    Entry::Phone
    Entry::Note
    Entry::Birthday
    Entry::Email
    Entry::Date
    Entry::FirstMet
    Entry::GiftList
  ].freeze
  SINGLETON_TYPES = %w[Entry::Birthday Entry::FirstMet].freeze
  UNCONFIGURED_VCARD_IMPORT_PROPERTY = :unconfigured
  UNSUPPORTED_VCARD_IMPORT_PROPERTY = :unsupported

  class_attribute :vcard_import_property, instance_accessor: false, default: UNCONFIGURED_VCARD_IMPORT_PROPERTY

  belongs_to :friend, touch: true
  has_one :entry_reminder, dependent: :destroy
  accepts_nested_attributes_for :entry_reminder, allow_destroy: true

  validates :type, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :entry_date, absence: true, unless: :date_entry?

  scope :ordered, -> { order(position: :asc, created_at: :desc, id: :desc) }

  def self.creatable_type(type)
    return unless CREATABLE_TYPES.include?(type)

    type.constantize
  end

  def self.vcard_importable_types
    @vcard_importable_types ||= CREATABLE_TYPES.filter_map do |type|
      entry_type = creatable_type(type)
      entry_type unless entry_type.vcard_import_property == UNSUPPORTED_VCARD_IMPORT_PROPERTY
    end.freeze
  end

  def self.vcard_importable_type_for(property)
    vcard_importable_types_by_property[property.to_sym]
  end

  def self.vcard_importable_types_by_property
    @vcard_importable_types_by_property ||= vcard_importable_types.index_by(&:vcard_import_property).freeze
  end
  private_class_method :vcard_importable_types_by_property

  private

  def date_entry?
    is_a?(Entry::Date)
  end
end
