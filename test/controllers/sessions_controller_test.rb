require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create blocks unconfirmed users when confirmation is required" do
    with_email_confirmation_required do
      @user.update!(confirmed_at: nil)
      post session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to new_session_path
      assert cookies[:session_id].blank?
    end
  end

  test "create allows confirmed users when confirmation is required" do
    with_email_confirmation_required do
      @user.update!(confirmed_at: Time.current)
      post session_path, params: { email_address: @user.email_address, password: "password" }

      assert_redirected_to root_path
      assert cookies[:session_id]
    end
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
