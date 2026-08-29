require "test_helper"

class BirthdayMonthSectionComponentTest < ViewComponent::TestCase
  test "renders a labeled month containing profile-linked birthdays" do
    birthday = entries(:ada_birthday)

    render_inline BirthdayMonthSectionComponent.new(month: 12, birthdays: [ birthday ], year: 2026)

    assert_selector "section[aria-labelledby='birthdays-month-12']"
    assert_selector "h2#birthdays-month-12"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.person_path(birthday.person)}']"
  end

  test "supports a nested heading inside the earlier birthdays disclosure" do
    render_inline BirthdayMonthSectionComponent.new(
      month: 12,
      birthdays: [ entries(:ada_birthday) ],
      year: 2026,
      heading_level: 3
    )

    assert_selector "h3#birthdays-month-12"
  end
end
