require "application_system_test_case"

class ContactTrackingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @today = @user.local_date
  end

  test "a reminder can be enabled from the collapsed profile settings with the keyboard" do
    @user.update!(theme: "dark")
    person = @user.people.create!(name: "Reminder Disclosure")
    sign_in_as @user
    page.current_window.resize_to(375, 800)

    visit person_path(person)

    assert_selector "html[data-theme='dark']"
    assert_no_selector "#last-contacted"
    assert_selector "#contact-reminder.dark\\:border-stone-700", text: "No contact reminder set"
    assert_selector "details[data-contact-reminder-settings]:not([open])"
    assert_no_selector "select[name='keep_in_touch_setting[cadence]']"

    find("summary", text: "Set a reminder").send_keys(:enter)

    assert_selector "details[data-contact-reminder-settings][open]"
    select "Weekly", from: "Frequency"
    click_button "Turn on reminder"

    assert_current_path person_path(person)
    assert_selector "#last-contacted[data-contact-tracking-state='not-logged']"
    assert_selector "#contact-reminder", text: /Frequency: Weekly/
    assert_selector "details[data-contact-reminder-settings]:not([open])"
  end

  test "opting out of an inherited reminder leaves a complete no-reminder state" do
    @user.update!(
      contact_reminder_cadence: "monthly",
      contact_reminders_enabled_on: @today,
      contact_reminder_first_reminder_on: @today.next_month
    )
    person = @user.people.create!(name: "Inherited Reminder")
    sign_in_as @user

    visit person_path(person)

    assert_selector "#last-contacted[data-contact-tracking-state='not-logged']"
    assert_selector "#contact-reminder", text: /Frequency: Monthly/

    find("summary", text: "Set a custom reminder").send_keys(:enter)
    click_button "Turn off reminder"

    assert_current_path person_path(person)
    assert_no_selector "#last-contacted"
    assert_selector "#contact-reminder", text: "Contact reminder off for this person"
    assert_selector "#contact-reminder", text: "Your account default is Monthly."
    assert_button "Use monthly reminder"
    assert_selector "details[data-contact-reminder-settings]:not([open])"

    click_button "Use monthly reminder"

    assert_current_path person_path(person)
    assert_selector "#last-contacted[data-contact-tracking-state='not-logged']"
    assert_selector "#contact-reminder", text: /Frequency: Monthly/
    assert_selector "#contact-reminder", text: /Using your account setting/
  end
end
