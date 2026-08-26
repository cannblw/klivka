require "test_helper"

class CategoryManagementComponentTest < ViewComponent::TestCase
  test "category management renders its count and accessible actions" do
    category = categories(:family)
    friends(:ada).update!(category: category)
    path = Rails.application.routes.url_helpers.category_path(category)

    render_inline(CategoryManagementComponent.new(category: category))

    assert_selector "section[aria-labelledby='category-#{category.id}-heading']"
    assert_selector "h2#category-#{category.id}-heading", text: category.name
    assert_selector "form[action='#{path}'] input[name='category[name]']"
    assert_selector "[data-controller='delete-category'][data-delete-category-url='#{path}']"
    assert_selector "[data-friend-count='1']"
    assert_selector "[data-controller='friend-autocomplete']"
    assignment_path = Rails.application.routes.url_helpers.friend_category_assignment_path(friends(:ada))
    assert_selector "a[href='#{Rails.application.routes.url_helpers.friend_path(friends(:ada))}'][data-turbo-frame='_top']"
    assert_selector "form[action='#{assignment_path}'] input[name='category_assignment[category_id]'][value='']", visible: :all
  end

  test "category management reveals the rename form after a validation error" do
    category = categories(:family)
    category.name = ""
    category.validate
    path = Rails.application.routes.url_helpers.category_path(category)

    render_inline(CategoryManagementComponent.new(category: category))

    assert_selector "[data-toggle-target='content']:not(.hidden) form[action='#{path}']"
    assert_selector "form[action='#{path}'] .text-red-600"
  end
end
