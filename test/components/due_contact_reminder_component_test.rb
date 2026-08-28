require "test_helper"

class DueContactReminderComponentTest < ViewComponent::TestCase
  test "offers contact and snooze actions for a due person" do
    person = people(:ada)
    due_reminder = DueContactRemindersQuery::Result.new(person:, reminder_on: Date.new(2026, 8, 21))
    routes = Rails.application.routes.url_helpers

    render_inline DueContactReminderComponent.new(due_reminder:)

    assert_link person.name, href: routes.person_path(person)
    assert_link href: routes.person_path(person, quick_interaction: "today")
    assert_selector "form[action='#{routes.snooze_person_keep_in_touch_setting_path(person)}']"
    assert_selector "input[name='return_to'][value='reminders']", visible: :hidden
    assert_selector "button[type='submit']"
  end
end
