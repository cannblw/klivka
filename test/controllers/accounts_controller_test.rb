require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out

    delete account_path, params: { account: { password: "password" } }

    assert_redirected_to new_session_url
    assert User.exists?(@user.id)
  end

  test "rejects an incorrect current password" do
    assert_no_enqueued_jobs only: AccountDeletion::ExternalCleanupJob do
      delete account_path, params: { account: { password: "wrong-password" } }
    end

    assert_redirected_to settings_url
    assert User.exists?(@user.id)
  end

  test "deletes only the authenticated account and invalidates every session" do
    account_id = @user.id
    other_user_id = users(:two).id
    @user.sessions.create!(user_agent: "another browser")

    assert_enqueued_with(job: AccountDeletion::ExternalCleanupJob, args: [ account_id ]) do
      delete account_path, params: { account: { password: "password" } }
    end

    assert_redirected_to new_session_url
    assert_not User.exists?(account_id)
    assert_empty Session.where(user_id: account_id)
    assert User.exists?(other_user_id)

    get settings_path
    assert_redirected_to new_session_url
  end

  test "does not delete the shared demo account" do
    with_demo_mode(user: @user) do
      assert_no_enqueued_jobs only: AccountDeletion::ExternalCleanupJob do
        delete account_path, params: { account: { password: "password" } }
      end

      assert_redirected_to root_url
      assert User.exists?(@user.id)
    end
  end
end
