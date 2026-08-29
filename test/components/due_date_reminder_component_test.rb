require "test_helper"

class DueDateReminderComponentTest < ViewComponent::TestCase
  test "shows the date label, person, and profile destination" do
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7), label: "Anniversary")
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: "one_time")
    delivery = ReminderDelivery.new(
      user: entry.person.user,
      source: reminder,
      reminder_on: Date.new(2026, 8, 8),
      occurrence_on: entry.entry_date
    )
    routes = Rails.application.routes.url_helpers

    render_inline DueDateReminderComponent.new(delivery:)

    person_path = routes.person_path(entry.person, from: "reminders", anchor: dom_id(entry))
    assert_text "Anniversary"
    assert_text I18n.l(entry.entry_date, format: :long)
    assert_link entry.person.name, href: person_path
    assert_link "View date", href: person_path
  end

  test "uses a calm fallback for an unlabeled date" do
    entry = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 9, 7))
    reminder = entry.create_entry_reminder!(lead_value: 30, lead_unit: "days", recurrence: "one_time")
    delivery = ReminderDelivery.new(
      user: entry.person.user,
      source: reminder,
      reminder_on: Date.new(2026, 8, 8),
      occurrence_on: entry.entry_date
    )

    render_inline DueDateReminderComponent.new(delivery:)

    assert_text "Important date"
  end
end
