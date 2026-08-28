require "test_helper"

class ContactReminderOrganizerPersonComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  test "renders a responsive searchable row with an accessible reminder control" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: user.local_date)
    person = people(:ada)

    render_inline ContactReminderOrganizerPersonComponent.new(person:)

    assert_selector "li[data-filter-list-target='item'][data-search-value='#{person.name}']"
    assert_selector ".sm\\:flex-row.sm\\:items-center"
    assert_selector "a[href='#{person_path(person)}']", text: person.name
    assert_selector "[data-contact-reminder-state]", text: "Default: Monthly"
    assert_selector "label.sr-only[for='contact-reminder-selection-#{person.id}']", text: "Contact reminder setting for #{person.name}"
    assert_selector "select#contact-reminder-selection-#{person.id}"
    assert_selector "option[selected][value='default']", text: "Use default (Monthly)"
    assert_selector "option[value='off']", text: "Off"
  end
end
