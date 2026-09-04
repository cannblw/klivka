require "application_system_test_case"

class AccountDeletionTest < ApplicationSystemTestCase
  test "downloads an optional export and permanently deletes the account after password confirmation" do
    user = users(:one)
    account_id = user.id
    sign_in_as user
    visit settings_path

    within "section", text: "Delete your account" do
      assert_link "Download your Klivka data", href: account_export_path
      click_button "Delete my account"
    end

    assert_selector "dialog#account-deletion-dialog[open]"
    fill_in "Current password", with: "wrong-password"
    click_button "Permanently delete my account"

    assert_selector "dialog#account-deletion-dialog[open]"
    assert_text "Enter your current password to delete your account."
    fill_in "Current password", with: "password"
    click_button "Permanently delete my account"

    assert_current_path new_session_path
    assert_text "Your Klivka account has been deleted."
    assert_not User.exists?(account_id)

    visit settings_path
    assert_current_path new_session_path
  end
end
