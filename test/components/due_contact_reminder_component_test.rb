require "test_helper"

class DueContactReminderComponentTest < ViewComponent::TestCase
  test "offers contact and snooze actions for a due person" do
    person = people(:ada)
    delivery = ReminderDelivery.new(user: person.user, source: person, reminder_on: Date.new(2026, 8, 21))
    routes = Rails.application.routes.url_helpers

    render_inline DueContactReminderComponent.new(delivery:)

    dialog_id = "#{QuickInteractionComponent::DOM_ID}-#{person.id}"
    assert_link person.name, href: routes.person_path(person)
    assert_selector "button[aria-controls='#{dialog_id}'][aria-haspopup='dialog']"
    assert_selector "dialog##{dialog_id}"
    assert_selector "form[action='#{routes.person_interactions_path(person)}'] input[name='return_to'][value='reminders']", visible: :all
    assert_selector "form[action='#{routes.snooze_person_keep_in_touch_setting_path(person)}']"
    assert_selector "input[name='return_to'][value='reminders']", visible: :hidden
    assert_selector "button[type='submit']"
  end
end
