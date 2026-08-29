require "test_helper"

class ReminderBellComponentTest < ViewComponent::TestCase
  test "renders a calm link when no reminders are actionable" do
    render_inline ReminderBellComponent.new(actionable: false)

    assert_selector "a[href='#{routes.reminders_path}'][data-reminder-bell][data-actionable='false'][aria-label]"
    assert_selector ".material-icons[aria-hidden='true']", text: "notifications_none"
    assert_no_selector "[data-reminder-indicator]"
  end

  test "renders a presence signal without a numeric count when reminders are actionable" do
    render_inline ReminderBellComponent.new(actionable: true)

    assert_selector "a[href='#{routes.reminders_path}'][data-reminder-bell][data-actionable='true'][aria-label]"
    assert_selector ".material-icons[aria-hidden='true']", text: "notifications"
    assert_selector "[data-reminder-indicator][aria-hidden='true']", text: ""
    assert_no_text(/\d/)
  end

  private

  def routes
    Rails.application.routes.url_helpers
  end
end
