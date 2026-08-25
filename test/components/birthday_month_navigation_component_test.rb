require "test_helper"

class BirthdayMonthNavigationComponentTest < ViewComponent::TestCase
  test "renders the agenda choice and every month as accessible links" do
    render_inline BirthdayMonthNavigationComponent.new(selected_month: nil)

    assert_selector "nav[aria-label] a", count: 13
    assert_selector "a[href='#{Rails.application.routes.url_helpers.birthdays_path}'][aria-current='page']"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.birthdays_path(month: 12)}']"
  end

  test "marks a focused month as the current page" do
    render_inline BirthdayMonthNavigationComponent.new(selected_month: 12)

    assert_selector "a[href='#{Rails.application.routes.url_helpers.birthdays_path(month: 12)}'][aria-current='page']"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.birthdays_path}'][aria-current]", count: 0
  end
end
