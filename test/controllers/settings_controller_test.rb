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
      default_reminder_lead_unit: "years",
      birthday_reminders_enabled: false,
      birthday_reminder_lead_value: 3,
      birthday_reminder_lead_unit: "days",
      contact_reminder_cadence: "quarterly",
      contact_reminders_enabled_on: Date.current
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
    assert_select "input[name='user[birthday_reminders_enabled]'][type='checkbox']:not([checked])", count: 1
    assert_select "input[name='user[birthday_reminder_lead_value]'][value='3']", count: 1
    assert_select "select[name='user[birthday_reminder_lead_unit]'] option[selected][value='days']", count: 1
    assert_select "input[name='user[contact_reminders_enabled]'][type='checkbox'][checked]", count: 1
    assert_select "select[name='user[contact_reminder_cadence]'] option[selected][value='quarterly']", count: 1
    assert_select "a[href='#{contact_methods_path}']"
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
        default_reminder_lead_unit: "days",
        birthday_reminders_enabled: "0",
        birthday_reminder_lead_value: "2",
        birthday_reminder_lead_unit: "years"
      }
    }

    user = users(:one).reload
    assert_not_predicate user, :reminder_in_app_enabled?
    assert_not_predicate user, :reminder_email_enabled?
    assert_equal 3, user.default_reminder_lead_value
    assert_equal "days", user.default_reminder_lead_unit
    assert_not_predicate user, :birthday_reminders_enabled?
    assert_equal 2, user.birthday_reminder_lead_value
    assert_equal "years", user.birthday_reminder_lead_unit
    assert_redirected_to settings_url
    follow_redirect!
    assert_select "#flash [role='status']", text: I18n.t("settings.update.updated")
  end

  test "enables account contact reminders on the user's current date" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles", contact_reminders_enabled_on: nil)

    travel_to Time.utc(2026, 8, 10, 0, 30) do
      patch settings_path, params: {
        user: { contact_reminders_enabled: "1", contact_reminder_cadence: "monthly" }
      }
    end

    user.reload
    assert_equal "monthly", user.contact_reminder_cadence
    assert_equal Date.new(2026, 8, 9), user.contact_reminders_enabled_on
  end

  test "changing account contact reminders clears inherited snoozes only" do
    user = users(:one)
    user.update!(contact_reminders_enabled_on: user.local_date)
    inherited_person = people(:ada)
    inherited_person.update!(contact_reminder_snoozed_until: user.local_date + 7.days)
    overridden_person = user.people.create!(name: "Individual reminder", contact_reminder_snoozed_until: user.local_date + 7.days)
    overridden_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: user.local_date)

    patch settings_path, params: { user: { contact_reminder_cadence: "quarterly" } }

    assert_nil inherited_person.reload.contact_reminder_snoozed_until
    assert_equal user.local_date + 7.days, overridden_person.reload.contact_reminder_snoozed_until
  end

  test "rejects an unsupported account contact reminder cadence without clearing snoozes" do
    user = users(:one)
    person = people(:ada)
    snoozed_until = user.local_date + 7.days
    person.update!(contact_reminder_snoozed_until: snoozed_until)

    patch settings_path, params: { user: { contact_reminder_cadence: "hourly" } }

    assert_response :unprocessable_entity
    assert_equal ContactReminder::GLOBAL_DEFAULT_CADENCE, user.reload.contact_reminder_cadence
    assert_equal snoozed_until, person.reload.contact_reminder_snoozed_until
  end

  test "update rejects an unsupported default reminder unit" do
    original_unit = users(:one).default_reminder_lead_unit

    patch settings_path, params: { user: { default_reminder_lead_unit: "weeks" } }

    assert_response :unprocessable_entity
    assert_equal original_unit, users(:one).reload.default_reminder_lead_unit
    assert_select "#reminder-settings-heading"
    assert_select ".text-red-600", text: /Default reminder unit/
  end

  test "update rejects an unsupported birthday reminder unit" do
    original_unit = users(:one).birthday_reminder_lead_unit

    patch settings_path, params: { user: { birthday_reminder_lead_unit: "weeks" } }

    assert_response :unprocessable_entity
    assert_equal original_unit, users(:one).reload.birthday_reminder_lead_unit
    assert_select "#reminder-settings-heading"
    assert_select ".text-red-600", text: /Birthday reminder unit/
  end
end
