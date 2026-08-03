require "test_helper"

class EntryCardComponentTest < ViewComponent::TestCase
  test "renders a type-labelled sortable entry card" do
    entry = entries(:phone)
    dom_id = ActionView::RecordIdentifier.dom_id(entry)

    render_inline(EntryCardComponent.new(entry: entry, friend: entry.friend))

    assert_selector "turbo-frame##{dom_id}[data-entry-sortable-target='item'][data-entry-id='#{entry.id}']"
    assert_selector "button[data-entry-sortable-target='handle'][data-action='keydown->entry-sortable#moveWithKeyboard']"
    assert_selector "button[aria-label='Drag entry to reorder. Use the up and down arrow keys to move it.']"
    assert_selector "p", text: "Phone"
    edit_path = Rails.application.routes.url_helpers.edit_friend_entry_path(entry.friend, entry)
    assert_selector "a[href='#{edit_path}'][data-turbo-frame='#{dom_id}']"
  end
end
