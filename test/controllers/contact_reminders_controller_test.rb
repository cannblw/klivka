require "test_helper"

class ContactRemindersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "contact reminder organizer requires authentication" do
    sign_out

    get contact_reminders_url

    assert_redirected_to new_session_url
  end

  test "organizer shows the default and active people in alphabetical order" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: user.local_date)
    archived_person = user.people.create!(name: "Archived person")
    archived_person.archive!

    get contact_reminders_url

    assert_response :success
    assert_select "header a[href='#{contact_reminders_path}']", text: "Contact reminders"
    assert_select "[data-contact-reminder-default='enabled']", text: /Monthly/
    assert_select "a[href='#{settings_path}']", text: "Change the default in Settings"
    assert_select "turbo-frame#contact_reminder_organizer"
    assert_select "input#contact-reminder-person-search[data-action='input->filter-list#filter']"
    assert_equal user.people.active.order(:name).pluck(:name).sort_by { PersonNameNormalizer.call(_1) },
      css_select("[data-filter-list-target='item']").map { _1["data-search-value"] }
    assert_select "[data-search-value='#{archived_person.name}']", count: 0
    assert_select "[data-search-value='#{people(:bob).name}']", count: 0
  end

  test "organizer shows inherited, custom, and off states" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: user.local_date)
    custom_person = user.people.create!(name: "Custom person")
    custom_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: user.local_date)
    off_person = user.people.create!(name: "Off person")
    off_person.create_keep_in_touch_setting!(cadence: "quarterly")

    get contact_reminders_url

    assert_select "[data-search-value='#{people(:ada).name}'] [data-contact-reminder-state]", text: "Default: Monthly"
    assert_select "[data-search-value='#{custom_person.name}'] [data-contact-reminder-state]", text: "Custom: Weekly"
    assert_select "[data-search-value='#{off_person.name}'] [data-contact-reminder-state]", text: "Off for this person"
    assert_select "form[action='#{contact_reminder_path(custom_person)}'] select option[selected][value='weekly']"
    assert_select "form[action='#{contact_reminder_path(off_person)}'] select option[selected][value='off']"
  end

  test "a person can return to the default reminder" do
    person = people(:ada)
    person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)
    person.update!(contact_reminder_snoozed_until: Date.current + 7.days)

    assert_difference "KeepInTouchSetting.count", -1 do
      patch contact_reminder_url(person), params: { contact_reminder: { selection: "default" } }
    end

    assert_nil person.reload.contact_reminder_snoozed_until
    assert_redirected_to contact_reminders_url
  end

  test "a person can opt out of an inherited reminder" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: user.local_date)

    assert_difference "KeepInTouchSetting.count", 1 do
      patch contact_reminder_url(people(:ada)), params: { contact_reminder: { selection: "off" } }
    end

    setting = people(:ada).reload.keep_in_touch_setting
    assert_equal "monthly", setting.cadence
    assert_nil setting.enabled_on
  end

  test "a person can use a custom cadence from the user's current date" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles")

    travel_to Time.utc(2026, 8, 10, 0, 30) do
      patch contact_reminder_url(people(:ada)), params: { contact_reminder: { selection: "quarterly" } }
    end

    setting = people(:ada).reload.keep_in_touch_setting
    assert_equal "quarterly", setting.cadence
    assert_equal Date.new(2026, 8, 9), setting.enabled_on
  end

  test "organizer rejects unsupported selections" do
    assert_no_difference "KeepInTouchSetting.count" do
      patch contact_reminder_url(people(:ada)), params: { contact_reminder: { selection: "hourly" } }
    end

    assert_redirected_to contact_reminders_url
    assert_equal "This contact reminder wasn't saved: Frequency is not available", flash[:alert]
  end

  test "organizer cannot change another user's person" do
    patch contact_reminder_url(people(:bob)), params: { contact_reminder: { selection: "weekly" } }

    assert_response :not_found
    assert_nil people(:bob).keep_in_touch_setting
  end

  test "organizer cannot change an archived person" do
    people(:ada).archive!

    patch contact_reminder_url(people(:ada)), params: { contact_reminder: { selection: "weekly" } }

    assert_response :not_found
    assert_nil people(:ada).keep_in_touch_setting
  end
end
