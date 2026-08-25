require "test_helper"

# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  birthday_reminder_lead_unit  :string           default("months"), not null
#  birthday_reminder_lead_value :integer          default(1), not null
#  birthday_reminders_enabled   :boolean          default(TRUE), not null
#  confirmed_at                 :datetime
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

  test "applies the configured reminder defaults to a new user" do
    user = User.new(email_address: "reminders@example.com", password: "a-safe-password")

    assert_predicate user, :reminder_in_app_enabled?
    assert_predicate user, :reminder_email_enabled?
    assert_equal 1, user.default_reminder_lead_value
    assert_equal "months", user.default_reminder_lead_unit
    assert_equal Rails.application.config.x.birthday_reminder_default_enabled, user.birthday_reminders_enabled
    assert_equal 1, user.birthday_reminder_lead_value
    assert_equal "months", user.birthday_reminder_lead_unit
  end

  test "the shared demo allows in-app reminders but suppresses email reminders" do
    user = users(:one)

    with_demo_mode(user:) do
      assert user.reminder_channel_enabled?("in_app")
      assert_not user.reminder_channel_enabled?("email")
    end

    assert user.reminder_channel_enabled?("email")
  end

  test "preserves explicit reminder preferences when application defaults differ" do
    configuration = Rails.application.config.x
    original_defaults = [
      configuration.reminder_default_in_app_enabled,
      configuration.reminder_default_email_enabled,
      configuration.reminder_default_lead_value,
      configuration.reminder_default_lead_unit,
      configuration.birthday_reminder_default_enabled
    ]
    configuration.reminder_default_in_app_enabled = false
    configuration.reminder_default_email_enabled = false
    configuration.reminder_default_lead_value = 2
    configuration.reminder_default_lead_unit = "years"
    configuration.birthday_reminder_default_enabled = false

    user = User.new(
      email_address: "custom-reminders@example.com",
      password: "a-safe-password",
      reminder_in_app_enabled: true,
      reminder_email_enabled: true,
      default_reminder_lead_value: 1,
      default_reminder_lead_unit: "months",
      birthday_reminders_enabled: true
    )

    assert_predicate user, :reminder_in_app_enabled?
    assert_predicate user, :reminder_email_enabled?
    assert_equal 1, user.default_reminder_lead_value
    assert_equal "months", user.default_reminder_lead_unit
    assert_predicate user, :birthday_reminders_enabled?
  ensure
    configuration.reminder_default_in_app_enabled,
      configuration.reminder_default_email_enabled,
      configuration.reminder_default_lead_value,
      configuration.reminder_default_lead_unit,
      configuration.birthday_reminder_default_enabled = original_defaults
  end

  test "rejects a reminder lead value below zero" do
    user = User.new(email_address: "negative-lead@example.com", password: "a-safe-password", default_reminder_lead_value: -1)

    assert_not_predicate user, :valid?
    assert user.errors.of_kind?(:default_reminder_lead_value, :greater_than_or_equal_to)
  end

  test "rejects a reminder lead value outside the portable integer range" do
    user = User.new(
      email_address: "overflowing-lead@example.com",
      password: "a-safe-password",
      default_reminder_lead_value: 2_147_483_648,
      default_reminder_lead_unit: "days"
    )

    assert_not_predicate user, :valid?
    assert user.errors.of_kind?(:default_reminder_lead_value, :less_than_or_equal_to)
  end

  test "rejects an unsupported reminder lead unit" do
    user = User.new(email_address: "unsupported-lead-unit@example.com", password: "a-safe-password", default_reminder_lead_unit: "weeks")

    assert_not_predicate user, :valid?
    assert user.errors.of_kind?(:default_reminder_lead_unit, :inclusion)
  end

  test "preserves birthday reminder preferences independently from general reminder defaults" do
    user = User.new(
      email_address: "birthday-reminders@example.com",
      password: "a-safe-password",
      default_reminder_lead_value: 2,
      default_reminder_lead_unit: "days",
      birthday_reminders_enabled: false,
      birthday_reminder_lead_value: 3,
      birthday_reminder_lead_unit: "months"
    )

    assert_not_predicate user, :birthday_reminders_enabled?
    assert_equal 3, user.birthday_reminder_lead_value
    assert_equal "months", user.birthday_reminder_lead_unit
  end

  test "rejects an invalid birthday reminder preference" do
    user = User.new(
      email_address: "invalid-birthday-reminders@example.com",
      password: "a-safe-password",
      birthday_reminders_enabled: nil,
      birthday_reminder_lead_value: -1,
      birthday_reminder_lead_unit: "weeks"
    )

    assert_not_predicate user, :valid?
    assert user.errors.of_kind?(:birthday_reminders_enabled, :inclusion)
    assert user.errors.of_kind?(:birthday_reminder_lead_value, :greater_than_or_equal_to)
    assert user.errors.of_kind?(:birthday_reminder_lead_unit, :inclusion)
  end

  test "database rejects a negative reminder lead value" do
    assert_raises ActiveRecord::StatementInvalid do
      users(:one).update_column(:default_reminder_lead_value, -1)
    end
  end

  test "database rejects reminder lead days outside the portable integer range" do
    # Bypass adapter-specific integer casting so both SQLite and PostgreSQL exercise the database boundary itself.
    overflowing_value = FriendCrm::MAX_INT32 + 1
    quoted_id = User.connection.quote(users(:one).id)

    assert_raises ActiveRecord::StatementInvalid do
      User.connection.execute(
        "UPDATE users SET default_reminder_lead_value = #{overflowing_value} WHERE id = #{quoted_id}"
      )
    end
  end
  test "database rejects an invalid birthday reminder preference" do
    assert_raises ActiveRecord::StatementInvalid do
      users(:one).update_column(:birthday_reminder_lead_value, -1)
    end
  end
end
