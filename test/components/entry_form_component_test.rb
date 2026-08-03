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
