require "test_helper"

class FriendCategoryComponentTest < ViewComponent::TestCase
  test "friend category renders the current optional assignment" do
    friend = friends(:ada)
    friend.update!(category: categories(:family))
    path = Rails.application.routes.url_helpers.friend_category_assignment_path(friend)

    render_inline FriendCategoryComponent.new(friend: friend, categories: users(:one).categories.order(:name))

    assert_selector "[data-controller='toggle'] [data-toggle-target='content']:not(.hidden)"
    assert_selector "button[aria-label] .material-icons[aria-hidden='true']", text: "edit"
    assert_selector "form[action='#{path}']", visible: :all
    assert_selector "select[name='category_assignment[category_id]'] option[selected][value='#{categories(:family).id}']"
    assert_selector "select[name='category_assignment[category_id]'] option[value='']"
  end
end
