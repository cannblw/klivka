require "application_system_test_case"

class BackNavigationTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
  end

  test "returns to the exact birthday view that opened a person" do
    visit birthdays_path(month: 12)
    click_link people(:ada).name

    assert_current_path person_path(people(:ada))
    click_link "Back"

    assert_current_path birthdays_path(month: 12)
  end

  test "uses the stable people fallback for a direct visit in a new tab" do
    new_window = open_new_window

    within_window new_window do
      visit person_path(people(:ada))
      click_link "Back"

      assert_current_path root_path
    end
  ensure
    new_window&.close
  end
end
