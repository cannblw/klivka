require "application_system_test_case"

class DisclosureTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
  end

  test "a disclosure reports its state and restores focus when dismissed with Escape" do
    visit people_path

    trigger = find("#people-collection-actions-trigger")
    assert_equal "people-collection-actions-panel", trigger["aria-controls"]
    assert_equal "false", trigger["aria-expanded"]

    trigger.click

    assert_equal "true", trigger["aria-expanded"]
    assert_selector "#people-collection-actions-panel:not(.hidden)"

    trigger.send_keys(:escape)

    assert_equal "false", trigger["aria-expanded"]
    assert_selector "#people-collection-actions-panel.hidden", visible: :all
    assert_selector "#people-collection-actions-trigger:focus"
  end
end
