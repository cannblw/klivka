require "test_helper"

class KeepInTouchSettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out

    post person_keep_in_touch_setting_url(people(:ada)), params: { keep_in_touch_setting: { cadence: "weekly" } }

    assert_redirected_to new_session_url
  end

  test "creates an enabled contact reminder on the user's current date" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles")
    sign_out
    sign_in_as user

    travel_to Time.utc(2026, 8, 10, 0, 30) do
      assert_difference "KeepInTouchSetting.count", 1 do
        post person_keep_in_touch_setting_url(people(:ada)), params: {
          keep_in_touch_setting: { cadence: "monthly" }
        }
      end
    end

    setting = people(:ada).reload.keep_in_touch_setting
    assert_equal "monthly", setting.cadence
    assert_equal Date.new(2026, 8, 9), setting.enabled_on
    assert_nil setting.person.contact_reminder_snoozed_until
    assert_redirected_to person_url(people(:ada))
  end

  test "rejects an invalid cadence" do
    assert_no_difference "KeepInTouchSetting.count" do
      post person_keep_in_touch_setting_url(people(:ada)), params: {
        keep_in_touch_setting: { cadence: "hourly" }
      }
    end

    assert_redirected_to person_url(people(:ada))
    assert_equal "This contact reminder wasn't saved: Frequency is not available", flash[:alert]
  end

  test "does not replace an existing setting when creation is repeated" do
    people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    assert_no_difference "KeepInTouchSetting.count" do
      post person_keep_in_touch_setting_url(people(:ada)), params: {
        keep_in_touch_setting: { cadence: "yearly" }
      }
    end

    assert_equal "weekly", people(:ada).reload.keep_in_touch_setting.cadence
    assert_equal "This contact reminder changed. Please review the latest details.", flash[:alert]
  end

  test "changes cadence and clears an existing snooze" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)
    setting.person.update!(contact_reminder_snoozed_until: Date.current + 7.days)

    patch person_keep_in_touch_setting_url(people(:ada)), params: {
      keep_in_touch_setting: { cadence: "yearly", lock_version: setting.lock_version }
    }

    setting.reload
    assert_equal "yearly", setting.cadence
    assert_nil setting.person.reload.contact_reminder_snoozed_until
  end

  test "re-enables a contact reminder on the user's current date" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly")

    patch enable_person_keep_in_touch_setting_url(people(:ada)), params: {
      keep_in_touch_setting: { cadence: "quarterly", lock_version: setting.lock_version }
    }

    setting.reload
    assert_equal "quarterly", setting.cadence
    assert_equal users(:one).local_date, setting.enabled_on
  end

  test "disables a setting while preserving its cadence" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "monthly", enabled_on: Date.current)
    setting.person.update!(contact_reminder_snoozed_until: Date.current + 7.days)

    patch disable_person_keep_in_touch_setting_url(people(:ada)), params: {
      keep_in_touch_setting: { lock_version: setting.lock_version }
    }

    setting.reload
    assert_equal "monthly", setting.cadence
    assert_nil setting.enabled_on
    assert_nil setting.person.reload.contact_reminder_snoozed_until
  end

  test "snoozes a contact reminder for one week from the user's current date" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    patch snooze_person_keep_in_touch_setting_url(people(:ada)), params: {
      keep_in_touch_setting: { lock_version: setting.lock_version }
    }

    assert_equal users(:one).local_date + KeepInTouchSetting::SNOOZE_DAYS.days,
      setting.person.reload.contact_reminder_snoozed_until
  end

  test "rejects a stale update" do
    setting = people(:ada).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)
    stale_lock_version = setting.lock_version
    setting.update!(cadence: "monthly")

    patch person_keep_in_touch_setting_url(people(:ada)), params: {
      keep_in_touch_setting: { cadence: "yearly", lock_version: stale_lock_version }
    }

    assert_equal "monthly", setting.reload.cadence
    assert_equal "This contact reminder changed. Please review the latest details.", flash[:alert]
  end

  test "does not access another user's setting" do
    setting = people(:bob).create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    patch disable_person_keep_in_touch_setting_url(people(:bob)), params: {
      keep_in_touch_setting: { lock_version: setting.lock_version }
    }

    assert_response :not_found
  end

  test "does not create a contact reminder for an archived person" do
    people(:ada).archive!

    assert_no_difference "KeepInTouchSetting.count" do
      post person_keep_in_touch_setting_url(people(:ada)), params: {
        keep_in_touch_setting: { cadence: "weekly" }
      }
    end

    assert_response :not_found
  end
end
