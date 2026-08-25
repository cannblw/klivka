require "test_helper"

class BirthdayReminderStatusComponentTest < ViewComponent::TestCase
  test "shows the global timing when birthday reminders can be delivered" do
    user = users(:one)
    user.update!(birthday_reminder_lead_value: 2, birthday_reminder_lead_unit: "days")

    render_inline BirthdayReminderStatusComponent.new(user:, enable_reminders_link: true)

    assert_selector "[data-birthday-reminder-status='enabled']"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.settings_path}']"
  end

  test "explains when birthday reminders are disabled" do
    user = users(:one)
    user.update!(birthday_reminders_enabled: false)

    render_inline BirthdayReminderStatusComponent.new(user:)

    assert_selector "[data-birthday-reminder-status='disabled']" do
      assert_selector "a[href='#{Rails.application.routes.url_helpers.settings_path}']"
    end
  end

  test "explains when birthday reminders have no delivery channel" do
    user = users(:one)
    user.update!(reminder_in_app_enabled: false, reminder_email_enabled: false)

    render_inline BirthdayReminderStatusComponent.new(user:)

    assert_selector "[data-birthday-reminder-status='no_channels']" do
      assert_selector "a[href='#{Rails.application.routes.url_helpers.settings_path}']"
    end
  end
end
