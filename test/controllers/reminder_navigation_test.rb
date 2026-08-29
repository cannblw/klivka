require "test_helper"

class ReminderNavigationTest < ActionDispatch::IntegrationTest
  test "the authenticated header links to reminders without a presence signal when none are actionable" do
    sign_in_as users(:one)

    get root_url

    assert_response :success
    assert_select "header a[href='#{reminders_path}'][data-reminder-bell][data-actionable='false'][aria-label]"
    assert_select "header [data-reminder-indicator]", count: 0
  end

  test "the authenticated header shows a presence signal for actionable reminders" do
    user = users(:one)
    person = user.people.create!(name: "Reminder presence")
    person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: user.local_date.yesterday)
    ReminderDelivery.create!(
      user:,
      source: person,
      channel: ReminderDelivery::IN_APP_CHANNEL,
      reminder_on: user.local_date,
      occurrence_on: user.local_date
    )
    sign_in_as user

    get root_url

    assert_response :success
    assert_select "header a[href='#{reminders_path}'][data-reminder-bell][data-actionable='true'][aria-label]"
    assert_select "header [data-reminder-indicator][aria-hidden='true']", count: 1
  end

  test "the header reconciles stale work before showing reminder presence" do
    user = users(:one)
    person = user.people.create!(name: "Stale reminder presence")
    person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: user.local_date.yesterday)
    delivery = ReminderDelivery.create!(
      user:,
      source: person,
      channel: ReminderDelivery::IN_APP_CHANNEL,
      reminder_on: user.local_date,
      occurrence_on: user.local_date
    )
    person.interactions.create!(occurred_on: user.local_date)
    sign_in_as user

    get root_url

    assert_select "header a[data-reminder-bell][data-actionable='false']"
    assert_select "header [data-reminder-indicator]", count: 0
    assert_equal ReminderDelivery::CANCELED_STATUS, delivery.reload.status
  end

  test "the unauthenticated header does not show the reminder bell" do
    get new_session_url

    assert_response :success
    assert_select "header [data-reminder-bell]", count: 0
  end
end
