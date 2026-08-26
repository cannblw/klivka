require "test_helper"

class FriendViewToggleComponentTest < ViewComponent::TestCase
  test "friend view toggle marks grouped view and omits default parameters" do
    render_inline FriendViewToggleComponent.new(view: "grouped", sort: FriendSearch::DEFAULT_SORT)

    assert_selector "nav[aria-label] a[aria-current='true'][href='#{Rails.application.routes.url_helpers.root_path}']"
    assert_selector "a[data-turbo-frame='friends_grid'][data-turbo-action='advance']", count: 2
  end

  test "friend view toggle preserves a nondefault sort in both choices" do
    render_inline FriendViewToggleComponent.new(view: "all", sort: "recently_updated")

    grouped_path = Rails.application.routes.url_helpers.root_path(sort: "recently_updated")
    all_path = Rails.application.routes.url_helpers.root_path(sort: "recently_updated", view: "all")
    assert_selector "a[href='#{grouped_path}']"
    assert_selector "a[aria-current='true'][href='#{all_path}']"
  end
end
