require "test_helper"

class EntryFormComponentTest < ViewComponent::TestCase
  test "renders only the selected entry type fields" do
    entry = Entry::Date.new(friend: friends(:ada), entry_date: Date.new(2020, 1, 2))

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "input[name='entry[type]'][value='Entry::Date']", visible: :all
    assert_selector "#date-fields"
    assert_selector "#phone-fields", count: 0
  end

  test "renders persisted entries without an editable type" do
    entry = entries(:phone)

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "input[name='entry[type]']", count: 0
    assert_selector "#phone-fields"
    assert_selector "a", text: "Delete"
  end

  test "renders reminder controls for a date entry using the account defaults" do
    entry = Entry::Date.new(friend: friends(:ada), entry_date: Date.new(2020, 1, 2))

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "form[data-controller~='reminder-date']"
    assert_selector "input[name='entry[entry_date]'][data-reminder-date-target='date'][data-action='change->reminder-date#update']"
    assert_selector "fieldset", text: "Reminder"
    assert_selector "input[name='entry[entry_reminder_attributes][_destroy]'][type='checkbox'][value='0']:not([checked])"
    assert_selector "input[name='entry[entry_reminder_attributes][lead_value]'][type='number'][value='1'][min='0'][max='#{FriendCrm::MAX_INT32}']"
    assert_selector "select[name='entry[entry_reminder_attributes][lead_unit]'] option[selected][value='months']"
    assert_selector "input[name='entry[entry_reminder_attributes][recurrence]'][type='radio'][value='one_time'][checked]"
    assert_selector "input[name='entry[entry_reminder_attributes][recurrence]'][type='radio'][value='yearly']:not([checked])"
    assert_nil entry.entry_reminder
  end

  test "explains leap-day reminder behavior when a leap-day reminder is enabled" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 2, 29))
    entry.create_entry_reminder!(lead_value: 1, lead_unit: "months", recurrence: EntryReminder::YEARLY_RECURRENCE)

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "[data-reminder-date-target='notice'][aria-live='polite']:not(.hidden)",
      text: "In non-leap years, Klivka will remind you on February 28."
  end

  test "explains the global reminder timing on a birthday form" do
    entry = entries(:ada_birthday)

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "[data-birthday-reminder-status='enabled']"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.settings_path}'][data-turbo-frame='_top']"
    assert_selector "input[name^='entry[entry_reminder_attributes]']", count: 0
    assert_selector "form[data-controller~='reminder-date']", count: 0
  end

  test "does not render reminder controls for a First Met entry" do
    entry = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019")

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "input[name='entry[entry_reminder_attributes][_destroy]']", count: 0
  end

  test "localizes date reminder controls" do
    entry = Entry::Date.new(friend: friends(:ada), entry_date: Date.new(2020, 1, 2))

    I18n.with_locale(:es) do
      render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

      assert_text "Recordatorio"
      assert_text "Recuérdame esta fecha"
      assert_text "Una vez"
      assert_text "Cada año"
      assert_selector "select[name='entry[entry_reminder_attributes][lead_unit]'] option", text: "Meses"
    end
  end

  test "renders separate year, optional month, and optional day fields for First Met" do
    entry = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019", entry_month: "5")

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "input[name='entry[entry_year]'][required]"
    assert_selector "select[name='entry[entry_month]'] option[selected][value='5']", text: "May"
    assert_selector "input[name='entry[entry_day]']"
    assert_selector "input[name='entry[entry_date]']", count: 0
  end

  test "renders gift ideas as an editable sortable checklist" do
    entry = Entry::GiftList.new(
      friend: friends(:ada),
      items: [ { "id" => "gift-1", "text" => "Iguana hammock", "checked" => true } ]
    )

    render_inline(EntryFormComponent.new(entry: entry, friend: entry.friend))

    assert_selector "#gift-list-fields[data-controller='gift-list']"
    assert_selector "li[data-gift-list-target='item']", count: 1
    assert_selector "ul[data-gift-list-target='list'].space-y-3"
    assert_selector "button[data-gift-list-target='handle'][data-action='keydown->gift-list#moveWithKeyboard'].w-10"
    assert_selector "input.h-5.w-5[type='checkbox'][name='entry[content][items][0][checked]'][checked]"
    assert_selector "input[type='text'][name='entry[content][items][0][text]'][value='Iguana hammock'][data-action='keydown.enter->gift-list#addAfter']"
    assert_selector "button[data-action='gift-list#remove']"
    assert_selector "button[data-action='gift-list#add']", text: "Add idea"
    assert_selector "template[data-gift-list-target='template']", visible: :all
    assert_selector "[data-gift-list-target='status'][aria-live='polite']"
  end
end
