require "test_helper"

class ContactReminderComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  test "renders an off state for a person without a reminder" do
    person = users(:one).people.create!(name: "Name Only")

    render_inline ContactReminderComponent.new(person: person, setting: nil)

    assert_selector "#contact-reminder"
    assert_selector "#contact-reminder-heading", text: "Keep in touch"
    assert_text "Choose how often you would like a gentle reminder to get in touch."
    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "select[name='keep_in_touch_setting[cadence]'] option", count: KeepInTouchSetting::CADENCES.size
    assert_selector "option[selected][value='weekly']", text: "Weekly"
    assert_selector "button", text: "Turn on reminder"
  end

  test "renders the next suggestion for an active reminder" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    render_inline ContactReminderComponent.new(person: person, setting: setting)

    assert_text "Next suggestion: #{I18n.l(Date.current + 7.days, format: :long)}"
    assert_text "Frequency: Weekly"
    assert_selector "summary", text: "Change frequency"
    assert_selector "form[action='#{person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
    assert_selector "form[action='#{disable_person_keep_in_touch_setting_path(person)}'][method='post']", visible: :all
  end

  test "uses a compact responsive layout and accepts parent spacing" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current)

    render_inline ContactReminderComponent.new(person: person, setting: setting, class: "mt-6", data: { testid: "reminder" })

    assert_selector "section#contact-reminder.mt-6.p-4.sm\\:p-5[data-testid='reminder']"
    assert_selector ".sm\\:flex-row.sm\\:justify-between"
    assert_selector ".bg-stone-100", text: /Next suggestion/
    assert_selector "details", text: /Change frequency/
  end

  test "renders contact and snooze actions when a reminder is due" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current - 7.days)

    render_inline ContactReminderComponent.new(person: person, setting: setting)

    assert_text "Would you like to get in touch with Name Only?"
    assert_selector "button[data-controller='open-quick-interaction'][aria-controls='#{QuickInteractionComponent::DOM_ID}'][aria-haspopup='dialog']", text: "Contacted today"
    assert_selector "form[action='#{snooze_person_keep_in_touch_setting_path(person)}'][method='post']"
    assert_selector "input[name='keep_in_touch_setting[lock_version]'][value='#{setting.lock_version}']", count: 3, visible: :all
    assert_selector "button", text: "Remind me in one week"
  end

  test "renders the snoozed state" do
    person = users(:one).people.create!(name: "Name Only")
    snoozed_until = Date.current + 7.days
    setting = person.create_keep_in_touch_setting!(cadence: "weekly", enabled_on: Date.current - 7.days)
    person.update!(contact_reminder_snoozed_until: snoozed_until)

    render_inline ContactReminderComponent.new(person: person, setting: setting)

    assert_text "Snoozed until #{I18n.l(snoozed_until, format: :long)}"
  end

  test "renders a disabled reminder with its previous frequency selected" do
    person = users(:one).people.create!(name: "Name Only")
    setting = person.create_keep_in_touch_setting!(cadence: "monthly")

    render_inline ContactReminderComponent.new(person: person, setting: setting)

    assert_text "The contact reminder is off."
    assert_selector "form[action='#{enable_person_keep_in_touch_setting_path(person)}'][method='post']"
    assert_selector "option[selected][value='monthly']", text: "Monthly"
  end
end
