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
    create_delivery(people(:ada))
    create_delivery(people(:grace))

    get reminders_url

    assert_response :success
    assert_select "h1", text: "Reminders"
    assert_select "a[href='#{person_path(people(:ada))}']"
    assert_select "a[href='#{person_path(people(:grace))}']"
    assert_select "a[href='#{person_path(future_person)}']", count: 0
    assert_select "dialog##{QuickInteractionComponent::DOM_ID}-#{people(:ada).id}"
    assert_select "dialog##{QuickInteractionComponent::DOM_ID}-#{people(:grace).id}"
    assert_select "dialog##{QuickInteractionComponent::DOM_ID}-#{future_person.id}", count: 0
    assert_select "form[action='#{person_interactions_path(people(:ada))}'] input[name='return_to'][value='reminders']"
    assert_select "form[action='#{snooze_person_keep_in_touch_setting_path(people(:ada))}'] input[name='return_to'][value='reminders']"
  end

  test "groups contact, birthday, and meaningful date reminders" do
    user = users(:one)
    today = user.local_date
    user.update!(
      contact_reminder_cadence: "weekly",
      contact_reminders_enabled_on: today - 7.days,
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days"
    )
    create_delivery(people(:ada))

    birthday_person = user.people.create!(name: "Birthday Person")
    birthday = Entry::Birthday.create!(person: birthday_person, entry_date: today.next_day - 30.years)
    create_delivery(birthday, occurrence_on: today.next_day)

    date_entry = Entry::Date.create!(person: people(:grace), entry_date: today.next_day, label: "Community dinner")
    date_reminder = date_entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    create_delivery(date_reminder, occurrence_on: today.next_day)

    get reminders_url

    assert_response :success
    assert_select "section[aria-labelledby='due-contact-reminders-heading']", text: /Ada/
    assert_select "section[aria-labelledby='due-birthday-reminders-heading']", text: /Birthday Person/
    assert_select "section[aria-labelledby='due-date-reminders-heading']", text: /Community dinner/
    assert_select "a[href='#{person_path(birthday_person)}']"
    assert_select "a[href='#{person_path(people(:grace), anchor: dom_id(date_entry))}']"
  end

  test "does not show another account's due reminders" do
    person = people(:bob)
    person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: users(:two).local_date - 1.day)
    create_delivery(person, user: users(:two))

    get reminders_url

    assert_select "main", text: /#{person.name}/, count: 0
  end

  test "shows a calm empty state when no reminders are due" do
    get reminders_url

    assert_response :success
    assert_select "ul", count: 0
    assert_select "main > a[href='#{root_path}'][data-controller='history-back']"
    assert_select "section[aria-labelledby='no-due-reminders-heading']", text: /Nothing needs your attention/
  end


  private

  def create_delivery(source, user: users(:one), occurrence_on: user.local_date)
    ReminderDelivery.create!(
      user:,
      source:,
      channel: ReminderDelivery::IN_APP_CHANNEL,
      reminder_on: user.local_date,
      occurrence_on:
    )
  end
end
