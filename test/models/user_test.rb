require "test_helper"

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
