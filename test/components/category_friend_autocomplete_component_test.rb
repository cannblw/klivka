require "test_helper"

class CategoryFriendAutocompleteComponentTest < ViewComponent::TestCase
  test "friend autocomplete exposes an accessible combobox and assignment form" do
    category = categories(:family)
    render_inline CategoryFriendAutocompleteComponent.new(category: category)

    suggestions_path = Rails.application.routes.url_helpers.friend_suggestions_categories_path(category_id: category.id)
    assert_selector "[data-controller='friend-autocomplete'][data-friend-autocomplete-url-value='#{suggestions_path}']"
    assert_selector "input[role='combobox'][aria-autocomplete='list'][aria-expanded='false'][aria-controls]"
    assert_selector "ul[role='listbox']"
    assert_selector "form[data-friend-autocomplete-target='form'] input[name='category_assignment[category_id]'][value='#{category.id}']", visible: :all
  end
end
