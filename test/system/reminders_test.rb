require "application_system_test_case"

class RemindersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @today = @user.local_date
    @user.update!(
      birthday_reminder_lead_value: 1,
      birthday_reminder_lead_unit: "days"
    )
    seed_contact_reminder("Contact Today Person")
    seed_contact_reminder("Snooze Person")
    seed_birthday_reminder
    seed_date_reminder
    sign_in_as @user
  end

  test "the reminder bell opens the grouped center and contact actions update it" do
    assert_selector "[data-reminder-bell][data-actionable='true'] [data-reminder-indicator]"

    find("[data-reminder-bell]").click

    assert_current_path reminders_path
    assert_selector "section[aria-labelledby='due-contact-reminders-heading']", text: "Contact Today Person"
    assert_selector "section[aria-labelledby='due-birthday-reminders-heading']", text: "Birthday Reminder Person"
    assert_selector "section[aria-labelledby='due-date-reminders-heading']", text: "Dinner anniversary"

    within("li", text: "Contact Today Person") do
      click_button "Contact today"
    end
    within("dialog[open]") do
      click_button "Save interaction"
    end

    assert_current_path reminders_path
    assert_no_selector "li", text: "Contact Today Person"

    within("li", text: "Snooze Person") do
      click_button "Remind me in one week"
    end

    assert_current_path reminders_path
    assert_no_selector "li", text: "Snooze Person"
    assert_selector "[data-reminder-bell][data-actionable='true'] [data-reminder-indicator]"

    within("section[aria-labelledby='due-birthday-reminders-heading']") do
      click_link "View person"
    end
    assert_selector "h1", text: "Birthday Reminder Person"
    click_link "Back"
    assert_current_path reminders_path

    click_link "Back"
    assert_current_path root_path
  end

  private

  def seed_contact_reminder(name)
    person = @user.people.create!(name:)
    person.create_keep_in_touch_setting!(cadence: "daily", enabled_on: @today.yesterday)
    create_delivery(person)
  end

  def seed_birthday_reminder
    person = @user.people.create!(name: "Birthday Reminder Person")
    birthday = Entry::Birthday.create!(person:, entry_date: @today.next_day - 30.years)
    create_delivery(birthday, occurrence_on: @today.next_day)
  end

  def seed_date_reminder
    person = @user.people.create!(name: "Date Reminder Person")
    entry = Entry::Date.create!(person:, entry_date: @today.next_day, label: "Dinner anniversary")
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "days", recurrence: "one_time")
    create_delivery(reminder, occurrence_on: @today.next_day)
  end

  def create_delivery(source, occurrence_on: @today)
    ReminderDelivery.create!(
      user: @user,
      source:,
      channel: ReminderDelivery::IN_APP_CHANNEL,
      reminder_on: @today,
      occurrence_on:
    )
  end
end
