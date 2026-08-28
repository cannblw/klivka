require "test_helper"

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "reminders require authentication" do
    sign_out

    get reminders_url

    assert_redirected_to new_session_url
  end

  test "shows every currently due contact reminder" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "weekly", contact_reminders_enabled_on: user.local_date - 7.days)
    future_person = user.people.create!(name: "Future person")
    future_person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: user.local_date)

    get reminders_url

    assert_response :success
    assert_select "h1", text: "Reminders"
    assert_select "a[href='#{person_path(people(:ada), quick_interaction: "today")}']"
    assert_select "a[href='#{person_path(people(:grace), quick_interaction: "today")}']"
    assert_select "a[href='#{person_path(future_person, quick_interaction: "today")}']", count: 0
    assert_select "form[action='#{snooze_person_keep_in_touch_setting_path(people(:ada))}'] input[name='return_to'][value='reminders']"
  end

  test "does not show another account's due reminders" do
    person = people(:bob)
    person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: users(:two).local_date - 1.day)

    get reminders_url

    assert_select "a[href='#{person_path(person)}']", count: 0
  end

  test "shows a calm empty state when no contact reminders are due" do
    get reminders_url

    assert_response :success
    assert_select "ul", count: 0
    assert_select "section p", text: "No contact reminders need your attention right now."
  end
end
