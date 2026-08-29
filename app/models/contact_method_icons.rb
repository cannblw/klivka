class ContactMethodIcons
  ICONS = {
    "material_icons" => %w[alternate_email call chat email forum groups language more_horiz sms videocam],
    "simple_icons" => %w[
      discord googlechat googlemeet imessage instagram kakaotalk line mastodon matrix messenger signal
      snapchat telegram threema viber vk wechat whatsapp zoom
    ]
  }.transform_values(&:freeze).freeze

  def self.valid?(library, name)
    return true if library.blank? && name.blank?
    return false if library.blank? || name.blank?

    ICONS.fetch(library, []).include?(name)
  end
end
