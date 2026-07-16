require "test_helper"

# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  confirmed_at    :datetime
#  email_address   :string           not null
#  password_digest :string           not null
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
end
