# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  birthday_reminder_lead_unit  :string           default("months"), not null
#  birthday_reminder_lead_value :integer          default(1), not null
#  birthday_reminders_enabled   :boolean          default(TRUE), not null
#  confirmed_at                 :datetime
#  contact_reminder_cadence     :string           default("monthly"), not null
#  contact_reminders_enabled_on :date
#  default_reminder_lead_unit   :string           default("months"), not null
#  default_reminder_lead_value  :integer          default(1), not null
#  email_address                :string           not null
#  locale                       :string
#  password_digest              :string           not null
#  reminder_email_enabled       :boolean          default(TRUE), not null
#  reminder_in_app_enabled      :boolean          default(TRUE), not null
#  reminders_scanned_through_on :date
#  theme                        :string
#  time_zone                    :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_users_on_email_address                 (email_address) UNIQUE
#  index_users_on_reminders_scanned_through_on  (reminders_scanned_through_on)
#
class User < ApplicationRecord
  REMINDER_LEAD_UNITS = Rails.application.config.x.reminder_lead_units

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :people, dependent: :destroy
  has_many :reminder_deliveries, dependent: :destroy
  has_many :vcard_imports, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :time_zone, with: ->(value) { value.to_s.strip.presence }

  attribute :reminder_in_app_enabled, :boolean, default: -> { Rails.application.config.x.reminder_default_in_app_enabled }
  attribute :reminder_email_enabled, :boolean, default: -> { Rails.application.config.x.reminder_default_email_enabled }
  attribute :default_reminder_lead_value, :integer, default: -> { Rails.application.config.x.reminder_default_lead_value }
  attribute :default_reminder_lead_unit, :string, default: -> { Rails.application.config.x.reminder_default_lead_unit }
  attribute :birthday_reminders_enabled, :boolean, default: -> { Rails.application.config.x.birthday_reminder_default_enabled }
  attribute :birthday_reminder_lead_value, :integer, default: -> { Rails.application.config.x.reminder_default_lead_value }
  attribute :birthday_reminder_lead_unit, :string, default: -> { Rails.application.config.x.reminder_default_lead_unit }

  after_initialize :set_default_time_zone, if: :new_record?

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :time_zone, presence: true
  validate :time_zone_is_supported
  validates :reminder_in_app_enabled, :reminder_email_enabled, :birthday_reminders_enabled, inclusion: { in: [ true, false ] }
  validates :default_reminder_lead_value, :birthday_reminder_lead_value,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: Klivka::MAX_INT32 }
  validates :default_reminder_lead_unit, :birthday_reminder_lead_unit, inclusion: { in: REMINDER_LEAD_UNITS.keys }
  validates :contact_reminder_cadence, inclusion: { in: ContactReminder::CADENCES }

  # The seeded development account deliberately uses a short, local-only password.
  validates :password, length: { minimum: 8 }, allow_nil: true, unless: -> { Rails.env.development? }

  generates_token_for :email_confirmation, expires_in: 2.days do
    email_address
  end

  before_create :autoconfirm, unless: -> { Rails.application.config.x.require_email_confirmation }

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end

  def local_date(at: Time.current)
    at.in_time_zone(time_zone).to_date
  end

  def reminder_channel_enabled?(channel)
    case channel.to_s
    when ReminderDelivery::IN_APP_CHANNEL then reminder_in_app_enabled?
    when ReminderDelivery::EMAIL_CHANNEL then reminder_email_enabled? && !shared_demo_account?
    else false
    end
  end

  def birthday_reminder_lead_days
    birthday_reminder_lead_value * REMINDER_LEAD_UNITS.fetch(birthday_reminder_lead_unit)
  end

  def contact_reminders_enabled?
    contact_reminders_enabled_on.present?
  end

  def contact_reminders_enabled
    contact_reminders_enabled?
  end

  def shared_demo_account?
    Rails.application.config.x.demo_mode && email_address == Rails.application.config.x.demo_user_email_address
  end

  private

  def set_default_time_zone
    self.time_zone ||= Rails.application.config.x.default_time_zone
  end

  def time_zone_is_supported
    return if time_zone.blank?

    TZInfo::Timezone.get(time_zone)
  rescue TZInfo::InvalidTimezoneIdentifier
    errors.add(:time_zone, :invalid)
  end

  def autoconfirm
    self.confirmed_at = Time.current
  end
end
