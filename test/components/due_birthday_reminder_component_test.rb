require "test_helper"

class DueBirthdayReminderComponentTest < ViewComponent::TestCase
  test "shows the birthday and relevant destinations" do
    birthday = entries(:ada_birthday)
    delivery = ReminderDelivery.new(
      user: birthday.person.user,
      source: birthday,
      reminder_on: Date.new(2026, 11, 10),
      occurrence_on: Date.new(2026, 12, 10)
    )
    routes = Rails.application.routes.url_helpers

    render_inline DueBirthdayReminderComponent.new(delivery:)

    assert_text birthday.person.name
    assert_text I18n.l(delivery.occurrence_on, format: :long)
    assert_link "View person", href: routes.person_path(birthday.person, from: "reminders")
    assert_link "Birthday settings", href: routes.settings_path
  end
end
