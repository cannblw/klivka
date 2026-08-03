class EntryTypePickerComponent < ViewComponent::Base
  COMMON_TYPES = %w[Entry::Phone Entry::Note Entry::Birthday Entry::Email].freeze
  ICONS = {
    "Entry::Phone" => "call",
    "Entry::Note" => "notes",
    "Entry::Birthday" => "cake",
    "Entry::Email" => "email",
    "Entry::Date" => "event",
    "Entry::FirstMet" => "handshake",
    "Entry::GiftList" => "featured_seasonal_and_gifts"
  }.freeze

  def initialize(friend:, types: Entry::CREATABLE_TYPES, searchable: false)
    @friend = friend
    @types = types
    @searchable = searchable
  end

  private

  attr_reader :friend, :types

  def searchable?
    @searchable
  end

  def kind_key(type)
    type.demodulize.underscore
  end

  def label_for(type)
    t("entries.kinds.#{kind_key(type)}")
  end

  def icon_for(type)
    ICONS.fetch(type)
  end

  def displayed_types
    searchable? ? types : types.reject { |type| unavailable?(type) }
  end

  def unavailable?(type)
    existing_singleton_types.include?(type)
  end

  def existing_singleton_types
    @existing_singleton_types ||= friend.entries.where(type: Entry::SINGLETON_TYPES).distinct.pluck(:type)
  end
end
