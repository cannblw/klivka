require "application_system_test_case"

class AccessibilityTest < ApplicationSystemTestCase
  test "the sign-in page passes automated accessibility checks" do
    visit new_session_path

    assert_accessible_page
  end

  test "the people index passes automated accessibility checks" do
    sign_in_as users(:one)

    assert_accessible_page
  end

  test "a populated person profile passes automated accessibility checks in dark mode" do
    user = users(:one)
    user.update!(theme: "dark")
    sign_in_as user
    visit person_path(people(:ada))

    assert_accessible_page
  end
end
