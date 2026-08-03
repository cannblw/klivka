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
end
