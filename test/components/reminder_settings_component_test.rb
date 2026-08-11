require "test_helper"

class ReminderSettingsComponentTest < ViewComponent::TestCase
  test "renders current reminder preferences" do
    user = users(:one)
    user.update!(
      reminder_in_app_enabled: false,
      reminder_email_enabled: true,
      default_reminder_lead_value: 2,
      default_reminder_lead_unit: "years"
    )

    render_inline ReminderSettingsComponent.new(user: user)

    assert_selector "#reminder-settings-heading", text: "Reminders"
    assert_selector "form[action='#{Rails.application.routes.url_helpers.settings_path}'][method='post']", visible: :all
    assert_selector "input[name='user[reminder_in_app_enabled]'][type='checkbox']", count: 1
    assert_selector "input[name='user[reminder_in_app_enabled]'][type='checkbox']:not([checked])", count: 1
    assert_selector "input[name='user[reminder_email_enabled]'][type='checkbox'][checked]", count: 1
    assert_selector "input[name='user[default_reminder_lead_value]'][type='number'][value='2'][min='0'][max='#{FriendCrm::MAX_INT32}'][step='1']", count: 1
    assert_selector "select[name='user[default_reminder_lead_unit]'] option[selected][value='years']", count: 1
    assert_selector "button[type='submit']", text: "Save reminder settings"
  end

  test "localizes reminder settings" do
    I18n.with_locale(:es) do
      render_inline ReminderSettingsComponent.new(user: users(:one))

      assert_selector "#reminder-settings-heading", text: "Recordatorios"
      assert_selector "option[value='months']", text: "Meses"
      assert_selector "button[type='submit']", text: "Guardar ajustes de recordatorios"
    end
  end
end
