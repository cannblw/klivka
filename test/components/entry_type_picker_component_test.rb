require "test_helper"

class EntryTypePickerComponentTest < ViewComponent::TestCase
  test "compact actions omit a singleton entry that already exists" do
    friend = friends(:ada)

    render_inline(EntryTypePickerComponent.new(friend: friend, types: EntryTypePickerComponent::COMMON_TYPES))

    available_type_count = EntryTypePickerComponent::COMMON_TYPES.size - 1
    assert_selector "li", count: available_type_count
    assert_selector "input[type='search']", count: 0
    assert_selector "a", text: "Birthday", count: 0
    path = Rails.application.routes.url_helpers.new_friend_entry_path(friend)
    assert_selector "a[href='#{path}']", text: "View all"
  end

  test "renders all entry types with accessible search" do
    friend = friends(:ada)

    render_inline(EntryTypePickerComponent.new(friend: friend, searchable: true))

    assert_selector "label.sr-only[for='entry-type-search']", text: "Search entry types"
    assert_selector "li[data-filter-list-target='item']", count: Entry::CREATABLE_TYPES.size
    assert_selector "[data-entry-type-unavailable]", text: /Birthday\s+Added/
    assert_selector "[data-filter-list-target='empty'][hidden]", text: "No matching entry types", visible: :all
  end
end
