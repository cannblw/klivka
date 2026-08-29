class CreateContactMethods < ActiveRecord::Migration[8.1]
  STRING_MAX_LENGTH = 255
  PROVIDED_METHODS = [
    { names: { "en" => "Call", "es" => "Llamada" }, icon: [ "material_icons", "call" ], enabled: true },
    { names: { "en" => "Text message", "es" => "Mensaje de texto" }, icon: [ "material_icons", "sms" ], enabled: true },
    { names: { "en" => "WhatsApp", "es" => "WhatsApp" }, icon: [ "simple_icons", "whatsapp" ], enabled: true },
    { names: { "en" => "Facebook Messenger", "es" => "Facebook Messenger" }, icon: [ "simple_icons", "messenger" ], enabled: true },
    { names: { "en" => "Video call", "es" => "Videollamada" }, icon: [ "material_icons", "videocam" ], enabled: true },
    { names: { "en" => "In person", "es" => "En persona" }, icon: [ "material_icons", "groups" ], enabled: true },
    { names: { "en" => "Other", "es" => "Otro" }, icon: [ "material_icons", "more_horiz" ], enabled: true },
    { names: { "en" => "Email", "es" => "Correo electrónico" }, icon: [ "material_icons", "email" ], enabled: false },
    { names: { "en" => "iMessage", "es" => "iMessage" }, icon: [ "simple_icons", "imessage" ], enabled: false },
    { names: { "en" => "FaceTime", "es" => "FaceTime" }, icon: [ "material_icons", "videocam" ], enabled: false },
    { names: { "en" => "Instagram", "es" => "Instagram" }, icon: [ "simple_icons", "instagram" ], enabled: false },
    { names: { "en" => "Signal", "es" => "Signal" }, icon: [ "simple_icons", "signal" ], enabled: false },
    { names: { "en" => "Telegram", "es" => "Telegram" }, icon: [ "simple_icons", "telegram" ], enabled: false },
    { names: { "en" => "WeChat", "es" => "WeChat" }, icon: [ "simple_icons", "wechat" ], enabled: false },
    { names: { "en" => "Snapchat", "es" => "Snapchat" }, icon: [ "simple_icons", "snapchat" ], enabled: false },
    { names: { "en" => "Discord", "es" => "Discord" }, icon: [ "simple_icons", "discord" ], enabled: false },
    { names: { "en" => "LINE", "es" => "LINE" }, icon: [ "simple_icons", "line" ], enabled: false },
    { names: { "en" => "Viber", "es" => "Viber" }, icon: [ "simple_icons", "viber" ], enabled: false },
    { names: { "en" => "VK", "es" => "VK" }, icon: [ "simple_icons", "vk" ], enabled: false },
    { names: { "en" => "KakaoTalk", "es" => "KakaoTalk" }, icon: [ "simple_icons", "kakaotalk" ], enabled: false },
    { names: { "en" => "Threema", "es" => "Threema" }, icon: [ "simple_icons", "threema" ], enabled: false },
    { names: { "en" => "Matrix", "es" => "Matrix" }, icon: [ "simple_icons", "matrix" ], enabled: false },
    { names: { "en" => "Mastodon", "es" => "Mastodon" }, icon: [ "simple_icons", "mastodon" ], enabled: false },
    { names: { "en" => "Google Chat", "es" => "Google Chat" }, icon: [ "simple_icons", "googlechat" ], enabled: false },
    { names: { "en" => "Google Meet", "es" => "Google Meet" }, icon: [ "simple_icons", "googlemeet" ], enabled: false },
    { names: { "en" => "Zoom", "es" => "Zoom" }, icon: [ "simple_icons", "zoom" ], enabled: false }
  ].freeze

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationContactMethod < ActiveRecord::Base
    self.table_name = "contact_methods"
  end

  def up
    create_table :contact_methods do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.string :icon_library
      t.string :icon_name
      t.integer :position
      t.boolean :enabled, null: false, default: false
      t.boolean :provided, null: false, default: false
      t.timestamps
    end

    add_index :contact_methods, [ :user_id, :normalized_name ], unique: true
    add_index :contact_methods, [ :user_id, :enabled, :position ]
    add_check_constraint :contact_methods,
      "length(name) <= #{STRING_MAX_LENGTH}",
      name: "contact_methods_name_length"
    add_check_constraint :contact_methods,
      "length(normalized_name) <= #{STRING_MAX_LENGTH}",
      name: "contact_methods_normalized_name_length"
    add_check_constraint :contact_methods,
      "icon_library IS NULL OR length(icon_library) <= #{STRING_MAX_LENGTH}",
      name: "contact_methods_icon_library_length"
    add_check_constraint :contact_methods,
      "icon_name IS NULL OR length(icon_name) <= #{STRING_MAX_LENGTH}",
      name: "contact_methods_icon_name_length"
    add_check_constraint :contact_methods,
      "(icon_library IS NULL AND icon_name IS NULL) OR (icon_library IS NOT NULL AND icon_name IS NOT NULL)",
      name: "contact_methods_icon_is_complete"
    add_check_constraint :contact_methods,
      "(enabled = TRUE AND position IS NOT NULL AND position >= 0) OR (enabled = FALSE AND position IS NULL)",
      name: "contact_methods_position_matches_enabled_state"
    add_check_constraint :contact_methods,
      "enabled IN (TRUE, FALSE) AND provided IN (TRUE, FALSE)",
      name: "contact_methods_boolean_states"

    seed_existing_users
  end

  def down
    drop_table :contact_methods
  end

  private

  def seed_existing_users
    now = Time.current

    MigrationUser.find_each do |user|
      enabled_position = 0

      PROVIDED_METHODS.each do |definition|
        enabled = definition.fetch(:enabled)
        icon_library, icon_name = definition.fetch(:icon)
        name = definition.fetch(:names).fetch(user.locale.to_s, definition.dig(:names, "en"))

        MigrationContactMethod.create!(
          user_id: user.id,
          name:,
          normalized_name: name.downcase,
          icon_library:,
          icon_name:,
          enabled:,
          provided: true,
          position: enabled ? enabled_position : nil,
          created_at: now,
          updated_at: now
        )

        enabled_position += 1 if enabled
      end
    end
  end
end
