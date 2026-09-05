require "application_system_test_case"

class BatchPersonCreationTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
  end

  test "batch review uses Turbo while showing validation and candidates" do
    click_button "More actions"
    click_button "Add several people"
    assert_selector "#people-creation-dialog[open]"
    assert_accessible_page
    page.execute_script("window.batchPreviewPageSentinel = true")

    within("#people-creation-dialog") { click_button "Review people" }

    assert_selector "#people-creation-dialog[open] textarea[aria-invalid='true']"
    assert page.evaluate_script("window.batchPreviewPageSentinel")

    fill_in "Names", with: "Marie Curie"
    click_button "Review people"

    assert_selector "h1", text: "Review people"
    assert_field "Name", with: "Marie Curie"
    assert page.evaluate_script("window.batchPreviewPageSentinel")
  end
end
