require "application_system_test_case"

class UnsavedChangesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @friend = friends(:ada)
    sign_in_as(@user)
  end

  test "discarding birthday changes continues to the selected destination" do
    visit edit_friend_entry_path(@friend, entries(:ada_birthday))
    fill_in "Birth year", with: "1816"

    click_link "Settings"
    assert_dialog_open

    click_link "Discard"

    assert_current_path settings_path
  end

  test "keeping entry changes stays on the form and a later discard continues navigation" do
    visit edit_friend_entry_path(@friend, entries(:phone))
    fill_in "Phone number", with: "555-9876"

    click_link "Cancel"
    assert_dialog_open
    click_button "Keep editing"

    assert_current_path edit_friend_entry_path(@friend, entries(:phone))
    assert_field "Phone number", with: "555-9876"

    click_link "Cancel"
    assert_dialog_open
    click_link "Discard"

    assert_current_path friend_path(@friend)
  end

  test "submitting a guarded form and navigating from a clean form do not show the dialog" do
    visit edit_friend_entry_path(@friend, entries(:phone))
    fill_in "Phone number", with: "555-9876"
    click_button "Save changes"

    assert_text "555-9876"
    assert_no_selector "#discard-changes-dialog[open]"

    visit friend_path(@friend)
    visit edit_friend_entry_path(@friend, entries(:phone))
    click_link "Cancel"

    assert_current_path friend_path(@friend)
    assert_no_selector "#discard-changes-dialog[open]"
  end

  test "navigation from an unguarded page remains unchanged" do
    visit friends_path
    click_link "Settings"

    assert_current_path settings_path
    assert_no_selector "#discard-changes-dialog[open]"
  end

  private

  def assert_dialog_open
    assert_selector "#discard-changes-dialog[open]"
  end
end
