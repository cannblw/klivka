class FriendSuggestionsComponent < ViewComponent::Base
  SUGGESTED_TYPES = %w[Entry::FirstMet Entry::Date Entry::GiftList].freeze
  ICONS = {
    "Entry::FirstMet" => "handshake",
    "Entry::Date" => "event",
    "Entry::GiftList" => "card_giftcard"
  }.freeze

  def initialize(friend:, entries:)
    @friend = friend
    @entry_types = entries.map(&:type)
  end

  private

  attr_reader :friend, :entry_types

  def suggestions
    @suggestions ||= SUGGESTED_TYPES.reject { |type| entry_types.include?(type) }
  end

  def label_for(type)
    t("entries.suggestions.#{type.demodulize.underscore}")
  end

  def icon_for(type)
    ICONS.fetch(type)
  end
end
