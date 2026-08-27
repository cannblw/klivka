require "test_helper"

class CategoryPersonAutocompleteComponentTest < ViewComponent::TestCase
  test "person autocomplete exposes an accessible combobox and assignment form" do
    category = categories(:family)
    render_inline CategoryPersonAutocompleteComponent.new(category: category)

    suggestions_path = Rails.application.routes.url_helpers.person_suggestions_categories_path(category_id: category.id)
    assert_selector "[data-controller='person-autocomplete'][data-person-autocomplete-url-value='#{suggestions_path}']"
    assert_selector "input[role='combobox'][aria-autocomplete='list'][aria-expanded='false'][aria-controls]"
    assert_selector "ul[role='listbox']"
    assert_selector "form[data-person-autocomplete-target='form'] input[name='category_assignment[category_id]'][value='#{category.id}']", visible: :all
  end
end
