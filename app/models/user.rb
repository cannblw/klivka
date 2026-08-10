# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  confirmed_at    :datetime
#  email_address   :string           not null
#  locale          :string
#  password_digest :string           not null
#  theme           :string
#  time_zone       :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :friends, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :time_zone, with: ->(value) { value.to_s.strip.presence }

  after_initialize :set_default_time_zone, if: :new_record?

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :time_zone, presence: true
  validate :time_zone_is_supported

  # Skipped in development so the seeded admin@example.com/admin account works
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
