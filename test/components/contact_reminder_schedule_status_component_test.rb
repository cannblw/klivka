require "test_helper"

class ContactReminderScheduleStatusComponentTest < ViewComponent::TestCase
  test "distinguishes the saved date from an unsaved calendar choice" do
    first_reminder_on = Date.new(2026, 9, 28)

    render_inline ContactReminderScheduleStatusComponent.new(first_reminder_on:)

    assert_selector "[data-contact-reminder-schedule-target='savedSchedule']" do
      assert_text "Currently scheduled: #{I18n.l(first_reminder_on, format: :long)}"
      assert_text "Save your changes to update this date."
    end
    assert_selector ".hidden[data-contact-reminder-schedule-target='unsavedSchedule']",
      text: "Your new schedule will appear after you save."
  end

  test "renders nothing without a saved schedule" do
    render_inline ContactReminderScheduleStatusComponent.new(first_reminder_on: nil)

    assert_no_selector "[data-contact-reminder-schedule-target]"
  end
end
