require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get settings_path

    assert_redirected_to new_session_url
  end

  test "show displays current preferences" do
    users(:one).update!(
      locale: "es",
      theme: "dark",
      reminder_in_app_enabled: false,
      reminder_email_enabled: true,
      default_reminder_lead_value: 2,
      default_reminder_lead_unit: "years"
    )

    get settings_path

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "h1", I18n.with_locale(:es) { I18n.t("settings.show.heading") }
    assert_select "main", /#{users(:one).email_address}/
    assert_select "input[type='radio'][value='es']", count: 1
    assert_select "input[type='radio'][value='dark']", count: 1
    assert_select "input[name='user[reminder_in_app_enabled]'][type='checkbox']:not([checked])", count: 1
    assert_select "input[name='user[reminder_email_enabled]'][type='checkbox'][checked]", count: 1
    assert_select "input[name='user[default_reminder_lead_value]'][type='number'][value='2']", count: 1
    assert_select "select[name='user[default_reminder_lead_unit]'] option[selected][value='years']", count: 1
  end

  test "update persists the locale and re-renders in that language" do
    patch settings_path, params: { user: { locale: "es" } }

    assert_redirected_to settings_url
    assert_equal "es", users(:one).reload.locale
    follow_redirect!
    assert_select "html[lang=es]"
    assert_select "h1", "Ajustes"
    assert_select "#flash [role='status']", text: I18n.t("settings.update.updated", locale: :es)
  end

  test "update persists the theme" do
    patch settings_path, params: { user: { theme: "dark" } }

    assert_redirected_to settings_url
    assert_equal "dark", users(:one).reload.theme
    follow_redirect!
    assert_select "html[data-theme=dark]"
  end

  test "update persists both preferences at once" do
    patch settings_path, params: { user: { locale: "es", theme: "dark" } }

    users(:one).reload
    assert_equal "es", users(:one).locale
    assert_equal "dark", users(:one).theme
    assert_redirected_to settings_url
  end

  test "update persists reminder settings" do
    patch settings_path, params: {
      user: {
        reminder_in_app_enabled: "0",
        reminder_email_enabled: "0",
        default_reminder_lead_value: "3",
        default_reminder_lead_unit: "days"
      }
    }

    user = users(:one).reload
    assert_not_predicate user, :reminder_in_app_enabled?
    assert_not_predicate user, :reminder_email_enabled?
    assert_equal 3, user.default_reminder_lead_value
    assert_equal "days", user.default_reminder_lead_unit
    assert_redirected_to settings_url
    follow_redirect!
    assert_select "#flash [role='status']", text: I18n.t("settings.update.updated")
  end

  test "update rejects an unsupported default reminder unit" do
    original_unit = users(:one).default_reminder_lead_unit

    patch settings_path, params: { user: { default_reminder_lead_unit: "weeks" } }

    assert_response :unprocessable_entity
    assert_equal original_unit, users(:one).reload.default_reminder_lead_unit
    assert_select "#reminder-settings-heading"
    assert_select ".text-red-600", text: /Default reminder unit/
  end
end
