require "application_system_test_case"

class ConfirmationDialogTest < ApplicationSystemTestCase
  setup do
    @person = people(:ada)
    sign_in_as users(:one)
  end

  test "a shared confirmation dialog archives a person and returns focus after cancellation" do
    visit person_path(@person)

    find("button[aria-haspopup='menu']").click
    click_button "Archive person"

    within("##{ConfirmDialogComponent::DOM_ID}[open]") do
      assert_text "Archive this person?"
      assert_selector "input[name='_method'][value='patch']", visible: :all
      assert_selector "button.bg-amber-600", text: "Archive person"
      click_button "Cancel"
    end
    assert_selector "#person-actions-menu-trigger:focus"

    find("button[aria-haspopup='menu']").click
    click_button "Archive person"
    within("##{ConfirmDialogComponent::DOM_ID}[open]") { click_button "Archive person" }

    assert_current_path root_path
    assert @person.reload.archived?
  end

  test "the shared confirmation dialog permanently deletes an entry" do
    entry = entries(:phone)
    visit edit_person_entry_path(@person, entry)

    click_button "Delete"

    within("##{ConfirmDialogComponent::DOM_ID}[open]") do
      assert_text "Delete this entry?"
      assert_selector "input[name='_method'][value='delete']", visible: :all
      assert_selector "button.bg-red-600", text: "Delete"
      click_button "Delete"
    end

    assert_no_selector "##{ConfirmDialogComponent::DOM_ID}[open]"
    assert_not Entry.exists?(entry.id)
  end
end
