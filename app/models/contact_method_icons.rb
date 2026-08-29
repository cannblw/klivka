class ContactMethodIcons
  ICONS = {
    "material_icons" => %w[alternate_email call chat email forum groups language more_horiz sms videocam],
    "simple_icons" => %w[
      discord googlechat googlemeet imessage instagram kakaotalk line mastodon matrix messenger signal
      snapchat telegram threema viber vk wechat whatsapp zoom
    ]
  }.transform_values(&:freeze).freeze

  OPTIONS = ICONS.flat_map do |library, names|
    names.map { |name| [ library, name ] }
  end.freeze

  LABEL_KEYS = {
    "material_icons:alternate_email" => "contact_methods.icons.material_icons.alternate_email",
    "material_icons:call" => "contact_methods.provided.call",
    "material_icons:chat" => "contact_methods.icons.material_icons.chat",
    "material_icons:email" => "contact_methods.provided.email",
    "material_icons:forum" => "contact_methods.icons.material_icons.forum",
    "material_icons:groups" => "contact_methods.provided.in_person",
    "material_icons:language" => "contact_methods.icons.material_icons.language",
    "material_icons:more_horiz" => "contact_methods.provided.other",
    "material_icons:sms" => "contact_methods.provided.text_message",
    "material_icons:videocam" => "contact_methods.provided.video_call",
    "simple_icons:discord" => "contact_methods.provided.discord",
    "simple_icons:googlechat" => "contact_methods.provided.google_chat",
    "simple_icons:googlemeet" => "contact_methods.provided.google_meet",
    "simple_icons:imessage" => "contact_methods.provided.imessage",
    "simple_icons:instagram" => "contact_methods.provided.instagram",
    "simple_icons:kakaotalk" => "contact_methods.provided.kakaotalk",
    "simple_icons:line" => "contact_methods.provided.line",
    "simple_icons:mastodon" => "contact_methods.provided.mastodon",
    "simple_icons:matrix" => "contact_methods.provided.matrix",
    "simple_icons:messenger" => "contact_methods.provided.messenger",
    "simple_icons:signal" => "contact_methods.provided.signal",
    "simple_icons:snapchat" => "contact_methods.provided.snapchat",
    "simple_icons:telegram" => "contact_methods.provided.telegram",
    "simple_icons:threema" => "contact_methods.provided.threema",
    "simple_icons:viber" => "contact_methods.provided.viber",
    "simple_icons:vk" => "contact_methods.provided.vk",
    "simple_icons:wechat" => "contact_methods.provided.wechat",
    "simple_icons:whatsapp" => "contact_methods.provided.whatsapp",
    "simple_icons:zoom" => "contact_methods.provided.zoom"
  }.freeze

  def self.valid?(library, name)
    return true if library.blank? && name.blank?
    return false if library.blank? || name.blank?

    ICONS.fetch(library, []).include?(name)
  end

  def self.label_key(library, name)
    LABEL_KEYS.fetch("#{library}:#{name}")
  end
end
