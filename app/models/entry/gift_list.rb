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
class Entry::GiftList < Entry
  BOOLEAN_TYPE = ActiveModel::Type::Boolean.new

  store_accessor :content, :title, :items

  before_validation :normalize_content

  validate :items_are_valid

  private

  def normalize_content
    used_ids = []

    self.title = title.to_s.strip.presence
    raw_items = items.respond_to?(:values) ? items.values : Array(items)
    self.items = raw_items.map do |item|
      item = item.respond_to?(:to_h) ? item.to_h.stringify_keys : {}
      id = unique_item_id(item["id"], used_ids)
      used_ids << id

      {
        "id" => id,
        "text" => item["text"].to_s.strip,
        "checked" => BOOLEAN_TYPE.cast(item["checked"]) || false
      }
    end
  end

  def unique_item_id(candidate, used_ids)
    id = candidate.to_s.strip.presence
    id = SecureRandom.hex(8) while id.nil? || used_ids.include?(id)
    id
  end

  def items_are_valid
    unless items.is_a?(Array) && items.any?
      errors.add(:items, :blank)
      return
    end

    items.each_with_index do |item, index|
      errors.add(:items, :invalid, index: index + 1) if item["text"].blank?
    end
  end
end
