require "test_helper"

class ContactReminderComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  test "renders an off state for a person without a reminder" do
    person = users(:one).people.create!(name: "Name Only")

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_selector "#contact-reminder"
    assert_selector "#contact-reminder-heading", text: "Keep in touch"
    assert_text "No contact reminder set"
    assert_selector "details[data-contact-reminder-settings]:not([open]) > summary", text: "Set a reminder"
    assert_selector "details", text: /Choose how often you would like a gentle reminder to get in touch/, visible: :all
    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "select[name='keep_in_touch_setting[cadence]'] option", count: KeepInTouchSetting::CADENCES.size, visible: :all
    assert_selector "option[selected][value='weekly']", text: "Weekly", visible: :all
    assert_selector "button", text: "Turn on reminder", visible: :all
  end

  test "renders the next suggestion for an active reminder" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Next reminder: #{I18n.l(Date.current + 7.days, format: :long)}"
    assert_text "Frequency: Weekly"
    assert_selector "details[data-contact-reminder-settings]:not([open]) > summary", text: "Change custom reminder"
    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "#contact-reminder > div form[action='#{disable_person_keep_in_touch_setting_path(person)}'][method='post']"
    assert_no_selector "details form[action='#{disable_person_keep_in_touch_setting_path(person)}']", visible: :all
  end

  test "uses a compact responsive layout and accepts parent spacing" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person), class: "mt-6", data: { testid: "reminder" })

    assert_selector "section#contact-reminder.mt-6.border-t.pt-5.dark\\:border-stone-700[data-testid='reminder']"
    assert_selector ".sm\\:flex-row.sm\\:justify-between"
    assert_selector ".bg-stone-100", text: /Next reminder/
    assert_selector "details", text: /Change custom reminder/
  end

  test "renders contact and snooze actions when a reminder is due" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current - 7.days)

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Would you like to get in touch with Name Only?"
    assert_selector "button[data-controller='open-quick-interaction'][aria-controls='#{QuickInteractionComponent::DOM_ID}'][aria-haspopup='dialog']", text: "Contacted today"
    assert_selector "form[action='#{snooze_person_keep_in_touch_setting_path(person)}'][method='post']"
    assert_selector "button", text: "Remind me in one week"
  end

  test "renders the snoozed state" do
    person = users(:one).people.create!(name: "Name Only")
    snoozed_until = Date.current + 7.days
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current - 7.days)
    person.update!(contact_reminder_snoozed_until: snoozed_until)

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Snoozed until #{I18n.l(snoozed_until, format: :long)}"
  end

  test "renders a disabled reminder with its previous frequency selected" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "monthly")

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Contact reminder off for this person"
    assert_no_text "Your account default is"
    assert_selector "form[action='#{enable_person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "option[selected][value='monthly']", text: "Monthly", visible: :all
    assert_no_selector "button", text: "Use default reminder", visible: :all
  end

  test "explains when an individual off setting overrides the account reminder" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: Date.current)
    person = user.people.create!(name: "Name Only")
    person.create_keep_in_touch_setting!(cadence: "monthly")

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Contact reminder off for this person"
    assert_text "Your account default is Monthly."
    assert_selector "#contact-reminder > div form button.text-amber-700", text: "Use monthly reminder"
    assert_no_selector "#contact-reminder > div form button.bg-amber-600", visible: :all
    assert_selector "details[data-contact-reminder-settings]:not([open]) > summary", text: "Choose a custom reminder"
    assert_no_selector "details form[action='#{person_keep_in_touch_setting_path(person)}'] input[name='_method'][value='delete']", visible: :all
  end

  test "renders an inherited reminder with account settings and per-person actions" do
    user = users(:one)
    user.update!(contact_reminder_cadence: "monthly", contact_reminders_enabled_on: Date.current)
    person = user.people.create!(name: "Name Only")

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_text "Frequency: Monthly"
    assert_text "Using your account setting. Change it in Settings."
    assert_no_text "No contact reminder set"
    assert_no_text "Contact reminder off for this person"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.settings_reminders_path(anchor: "contact-reminders")}']", text: "Settings"
    assert_selector "details[data-contact-reminder-settings]:not([open]) > summary", text: "Set a custom reminder"
    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "#contact-reminder > div form[action='#{disable_person_keep_in_touch_setting_path(person)}'][method='post']"
  end

  test "renders a reset action for an individual override" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "monthly", enabled_on: Date.current)

    render_inline ContactReminderComponent.new(person:, reminder: ContactReminder.for(person))

    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post'] input[name='_method'][value='delete']", visible: :all
    assert_selector %(button[title="Use the contact reminder choice from Settings for this person."]), text: "Use default reminder", visible: :all
  end
end
