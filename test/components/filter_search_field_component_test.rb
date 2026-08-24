require "test_helper"

class FilterSearchFieldComponentTest < ViewComponent::TestCase
  test "filter search field component connects an accessible search to the filter list" do
    render_inline FilterSearchFieldComponent.new(
      id: "contact-search",
      label: "Search contacts",
      placeholder: "Search"
    )

    assert_selector "label.sr-only[for='contact-search']", text: "Search contacts"
    assert_selector "input#contact-search[type='search'][autocomplete='off'][data-action='input->filter-list#filter']"
  end
end
