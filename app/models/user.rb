class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Skipped in development so the seeded admin@example.com/admin account works
  validates :password, length: { minimum: 8 }, allow_nil: true, unless: -> { Rails.env.development? }
end
