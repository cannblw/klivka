# == Schema Information
#
# Table name: contact_methods
#
#  id              :integer          not null, primary key
#  enabled         :boolean          default(FALSE), not null
#  icon_library    :string
#  icon_name       :string
#  name            :string           not null
#  normalized_name :string           not null
#  position        :integer
#  provided        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_contact_methods_on_user_id                           (user_id)
#  index_contact_methods_on_user_id_and_enabled_and_position  (user_id,enabled,position)
#  index_contact_methods_on_user_id_and_normalized_name       (user_id,normalized_name) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class ContactMethod < ApplicationRecord
  PROVIDED_METHODS = [
    { key: "call", icon: [ "material_icons", "call" ], enabled: true },
    { key: "text_message", icon: [ "material_icons", "sms" ], enabled: true },
    { key: "whatsapp", icon: [ "simple_icons", "whatsapp" ], enabled: true },
    { key: "messenger", icon: [ "simple_icons", "messenger" ], enabled: true },
    { key: "video_call", icon: [ "material_icons", "videocam" ], enabled: true },
    { key: "in_person", icon: [ "material_icons", "groups" ], enabled: true },
    { key: "other", icon: [ "material_icons", "more_horiz" ], enabled: true },
    { key: "email", icon: [ "material_icons", "email" ], enabled: false },
    { key: "imessage", icon: [ "simple_icons", "imessage" ], enabled: false },
    { key: "facetime", icon: [ "material_icons", "videocam" ], enabled: false },
    { key: "instagram", icon: [ "simple_icons", "instagram" ], enabled: false },
    { key: "signal", icon: [ "simple_icons", "signal" ], enabled: false },
    { key: "telegram", icon: [ "simple_icons", "telegram" ], enabled: false },
    { key: "wechat", icon: [ "simple_icons", "wechat" ], enabled: false },
    { key: "snapchat", icon: [ "simple_icons", "snapchat" ], enabled: false },
    { key: "discord", icon: [ "simple_icons", "discord" ], enabled: false },
    { key: "line", icon: [ "simple_icons", "line" ], enabled: false },
    { key: "viber", icon: [ "simple_icons", "viber" ], enabled: false },
    { key: "vk", icon: [ "simple_icons", "vk" ], enabled: false },
    { key: "kakaotalk", icon: [ "simple_icons", "kakaotalk" ], enabled: false },
    { key: "threema", icon: [ "simple_icons", "threema" ], enabled: false },
    { key: "matrix", icon: [ "simple_icons", "matrix" ], enabled: false },
    { key: "mastodon", icon: [ "simple_icons", "mastodon" ], enabled: false },
    { key: "google_chat", icon: [ "simple_icons", "googlechat" ], enabled: false },
    { key: "google_meet", icon: [ "simple_icons", "googlemeet" ], enabled: false },
    { key: "zoom", icon: [ "simple_icons", "zoom" ], enabled: false }
  ].freeze

  belongs_to :user

  before_validation :normalize_name

  validates :name, presence: true, length: { maximum: Klivka::STRING_MAX_LENGTH }
  validates :normalized_name, presence: true, length: { maximum: Klivka::STRING_MAX_LENGTH }
  validates :enabled, :provided, inclusion: { in: [ true, false ] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :enabled?
  validates :position, absence: true, unless: :enabled?
  validate :name_is_unique_for_user
  validate :icon_is_supported

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :provided, -> { where(provided: true) }
  scope :ordered, -> { order(:position, :id) }

  def self.create_provided_for!(user, locale: I18n.locale)
    enabled_position = 0

    PROVIDED_METHODS.each do |definition|
      enabled = definition.fetch(:enabled)
      icon_library, icon_name = definition.fetch(:icon)

      user.contact_methods.create!(
        name: I18n.t("contact_methods.provided.#{definition.fetch(:key)}", locale:),
        icon_library:,
        icon_name:,
        enabled:,
        provided: true,
        position: enabled ? enabled_position : nil
      )

      enabled_position += 1 if enabled
    end
  end

  private

  def normalize_name
    self.name = StringNormalizer.call(name)
    self.normalized_name = name&.downcase
  end

  def name_is_unique_for_user
    return if normalized_name.blank? || user.nil?
    return unless user.contact_methods.where(normalized_name:).where.not(id:).exists?

    errors.add(:name, :taken)
  end

  def icon_is_supported
    return if ContactMethodIcons.valid?(icon_library, icon_name)

    errors.add(:icon_name, :inclusion)
  end
end
