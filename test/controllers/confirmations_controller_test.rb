require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "unconfirmed@example.com", password: "a-safe-password")
    # Creation autoconfirms while the flag is off, so unconfirm explicitly
    @user.update!(confirmed_at: nil)
  end

  test "show confirms the user with a valid token" do
    get confirmation_path(@user.generate_token_for(:email_confirmation))

    assert_redirected_to new_session_url
    assert @user.reload.confirmed?
    follow_redirect!
    assert_select "#flash", /Email confirmed/
  end

  test "show rejects an invalid token" do
    get confirmation_path("garbage")

    assert_redirected_to new_session_url
    assert_not @user.reload.confirmed?
    follow_redirect!
    assert_select "#flash", /invalid or has expired/
  end

  test "show rejects an expired token" do
    token = @user.generate_token_for(:email_confirmation)

    travel 3.days do
      get confirmation_path(token)

      assert_redirected_to new_session_url
      assert_not @user.reload.confirmed?
    end
  end
end
