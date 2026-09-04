require "application_system_test_case"

class UnsavedChangesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @person = people(:ada)
    sign_in_as(@user)
  end

  test "discarding birthday changes continues to the selected destination" do
    visit edit_person_entry_path(@person, entries(:ada_birthday))
    fill_in "Birth year", with: "1816"

    click_link "Settings"
    assert_dialog_open

    click_button "Discard"

    assert_current_path settings_path
  end

  test "keeping entry changes stays on the form and a later discard continues navigation" do
    visit edit_person_entry_path(@person, entries(:phone))
    fill_in "Phone number", with: "555-9876"

    click_link "Cancel"
    assert_dialog_open
    click_button "Keep editing"

    assert_current_path edit_person_entry_path(@person, entries(:phone))
    assert_field "Phone number", with: "555-9876"

    click_link "Cancel"
    assert_dialog_open
    click_button "Discard"

    assert_current_path person_path(@person)
  end

  test "submitting a guarded form and navigating from a clean form do not show the dialog" do
    visit edit_person_entry_path(@person, entries(:phone))
    fill_in "Phone number", with: "555-9876"
    click_button "Save changes"

    assert_text "555-9876"
    assert_no_selector "##{ConfirmDialogComponent::DOM_ID}[open]"

    visit person_path(@person)
    visit edit_person_entry_path(@person, entries(:phone))
    click_link "Cancel"

    assert_current_path person_path(@person)
    assert_no_selector "##{ConfirmDialogComponent::DOM_ID}[open]"
  end

  test "navigation from an unguarded page remains unchanged" do
    visit people_path
    click_link "Settings"

    assert_current_path settings_path
    assert_no_selector "##{ConfirmDialogComponent::DOM_ID}[open]"
  end

  private

  def assert_dialog_open
    assert_selector "##{ConfirmDialogComponent::DOM_ID}[open]"
  end
end
