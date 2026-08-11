require "test_helper"

class EntryCardComponentTest < ViewComponent::TestCase
  test "renders a type-labelled sortable entry card" do
    entry = entries(:phone)
    dom_id = ActionView::RecordIdentifier.dom_id(entry)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_selector "turbo-frame##{dom_id}.block[data-entry-sortable-target='item'][data-entry-id='#{entry.id}']"
    assert_selector "[data-entry-sortable-target='dropTarget'].relative"
    assert_selector "button[data-entry-sortable-target='handle'][data-action='keydown->entry-sortable#moveWithKeyboard'].w-10"
    assert_selector "button[aria-label='Drag entry to reorder. Use the up and down arrow keys to move it.']"
    assert_selector "p", text: "Phone"
    edit_path = Rails.application.routes.url_helpers.edit_friend_entry_path(entry.friend, entry)
    assert_selector "a[href='#{edit_path}'][data-turbo-frame='#{dom_id}']"
  end

  test "renders elapsed years for a first met entry" do
    travel_to Date.new(2026, 8, 3) do
      entry = Entry::FirstMet.create!(
        friend: friends(:ada),
        entry_date: Date.new(2019, 8, 1),
        content: { "date_precision" => "month" },
        created_at: Time.current
      )

      render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

      assert_text "August 2019"
      assert_text "(7 years ago)"
    end
  end

  test "shows reminder timing as accessible text when a date reminder is enabled" do
    entry = entries(:ada_birthday)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_selector "div.flex.items-center.gap-2" do
      assert_text I18n.l(entry.entry_date, format: :long)
      assert_text "Yearly reminder: 1 month before"
      assert_selector ".material-icons[aria-hidden='true']", text: "notifications_none"
    end
  end

  test "does not show reminder metadata when an entry has no reminder" do
    entry = entries(:phone)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_no_text "reminder:"
    assert_selector ".material-icons", text: "notifications_none", count: 0
  end

  test "describes a same-day reminder naturally in Spanish" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2026, 8, 11), label: "Aniversario")
    entry.create_entry_reminder!(lead_value: 0, lead_unit: "days")

    I18n.with_locale(:es) do
      render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

      assert_text "Recordatorio único: el mismo día"
    end
  end

  test "explains the leap-day reminder rule on a saved entry" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 2, 29))
    entry.create_entry_reminder!(lead_value: 1, lead_unit: "months", recurrence: EntryReminder::YEARLY_RECURRENCE)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_text "In non-leap years, Klivka will remind you on February 28."
  end

  test "does not show the leap-day rule for a one-time reminder" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2028, 2, 29))
    entry.create_entry_reminder!(lead_value: 1, lead_unit: "months", recurrence: EntryReminder::ONE_TIME_RECURRENCE)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_text "One-time reminder: 1 month before"
    assert_no_text "In non-leap years"
  end
end
