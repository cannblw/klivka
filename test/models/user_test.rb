require "test_helper"

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
class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "rejects passwords shorter than 8 characters" do
    user = User.new(email_address: "short@example.com", password: "1234567")

    assert_not user.valid?
    assert user.errors.of_kind?(:password, :too_short)
  end

  test "stores a locale preference" do
    user = User.new(email_address: "loc@example.com", password: "a-safe-password", locale: "es")
    assert_equal "es", user.locale
  end

  test "stores a theme preference" do
    user = User.new(email_address: "theme@example.com", password: "a-safe-password", theme: "dark")
    assert_equal "dark", user.theme
  end

  test "defaults a new user to the configured timezone" do
    user = User.new(email_address: "timezone@example.com", password: "a-safe-password")

    assert_equal Rails.application.config.x.default_time_zone, user.time_zone
  end

  test "normalizes and accepts an IANA timezone" do
    user = User.new(email_address: "timezone@example.com", password: "a-safe-password", time_zone: " Europe/Madrid ")

    assert_predicate user, :valid?
    assert_equal "Europe/Madrid", user.time_zone
  end

  test "rejects an unknown timezone" do
    user = User.new(email_address: "timezone@example.com", password: "a-safe-password", time_zone: "Mars/Olympus_Mons")

    assert_not_predicate user, :valid?
    assert user.errors.of_kind?(:time_zone, :invalid)
  end

  test "derives a calendar date in the user's timezone" do
    user = User.new(email_address: "timezone@example.com", password: "a-safe-password", time_zone: "America/Los_Angeles")

    assert_equal Date.new(2026, 8, 9), user.local_date(at: Time.utc(2026, 8, 10, 0, 30))
  end
end
