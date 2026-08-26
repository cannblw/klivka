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
