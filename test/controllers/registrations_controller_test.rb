require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the signup form" do
    get signup_path

    assert_response :success
    assert_select "h1", "Create your account"
  end

  test "create signs the user up and in" do
    assert_difference "User.count", 1 do
      post signup_path, params: { user: { email_address: "new@example.com", password: "a-safe-password" } }
    end

    assert_redirected_to root_url
    assert cookies[:session_id]
    assert User.find_by!(email_address: "new@example.com").confirmed?
    follow_redirect!
    assert_select "h1", "Friends"
  end

  test "create with confirmation required sends an email instead of signing in" do
    with_email_confirmation_required do
      assert_difference "User.count", 1 do
        post signup_path, params: { user: { email_address: "new@example.com", password: "a-safe-password" } }
      end

      user = User.find_by!(email_address: "new@example.com")
      assert_not user.confirmed?
      assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [ user ]
      assert_redirected_to new_session_url
      assert cookies[:session_id].blank?
    end
  end

  test "create rejects a taken email address" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: { email_address: users(:one).email_address, password: "a-safe-password" } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /taken/
  end

  test "create rejects an invalid email address" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: { email_address: "not-an-email", password: "a-safe-password" } }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects a short password" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: { email_address: "new@example.com", password: "short" } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /too short/
  end

  test "login page links to registration" do
    get new_session_path

    assert_select "a[href='#{signup_path}']"
  end
end
