require "test_helper"

class ContactReminderScheduleFieldsComponentTest < ViewComponent::TestCase
  test "renders only the current cadence control as enabled" do
    render_inline ContactReminderScheduleFieldsComponent.new(
      scope: "contact_reminder",
      cadence: "weekly",
      first_reminder_on: Date.new(2026, 9, 1),
      today: Date.new(2026, 8, 30),
      id_prefix: "schedule"
    )

    assert_selector "select[name='contact_reminder[first_reminder_weekday]']:not([disabled]) option[selected][value='2']"
    assert_selector "input[name='contact_reminder[first_reminder_date]'][disabled]"
    assert_selector "input[name='contact_reminder[contact_reminder_schedule_changed]'][value='0']", visible: :all
  end

  test "renders localized month and day choices for a yearly reminder" do
    I18n.with_locale(:es) do
      render_inline ContactReminderScheduleFieldsComponent.new(
        scope: "user",
        cadence: "yearly",
        first_reminder_on: Date.new(2027, 5, 12),
        today: Date.new(2026, 8, 30),
        id_prefix: "schedule"
      )

      assert_text "Mes y día del primer recordatorio"
      assert_selector "select[name='user[first_reminder_month]'] option[selected][value='5']", text: "mayo"
      assert_selector "select[name='user[first_reminder_day]'] option[selected][value='12']"
    end
  end
end
