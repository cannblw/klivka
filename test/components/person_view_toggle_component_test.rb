require "test_helper"

class PersonViewToggleComponentTest < ViewComponent::TestCase
  test "person view toggle marks grouped view and omits default parameters" do
    render_inline PersonViewToggleComponent.new(view: "grouped")

    assert_selector "nav[aria-label] a[aria-current='true'][href='#{Rails.application.routes.url_helpers.root_path}']"
    assert_selector "a[data-turbo-frame='people_grid'][data-turbo-action='advance']", count: 2
  end

  test "person view toggle preserves a nondefault sort in both choices" do
    render_inline PersonViewToggleComponent.new(view: "all", query_params: { sort: "recently_updated" })

    grouped_path = Rails.application.routes.url_helpers.root_path(sort: "recently_updated")
    all_path = Rails.application.routes.url_helpers.root_path(sort: "recently_updated", view: "all")
    assert_selector "a[href='#{grouped_path}']"
    assert_selector "a[aria-current='true'][href='#{all_path}']"
  end

  test "person view toggle preserves the supplied query state" do
    query_params = { sort: "recently_added", birthday: "missing", has_blocks: [ "email" ] }
    render_inline PersonViewToggleComponent.new(view: "grouped", query_params:)

    grouped_path = Rails.application.routes.url_helpers.root_path(**query_params)
    all_path = Rails.application.routes.url_helpers.root_path(**query_params, view: "all")
    assert_selector "a[aria-current='true'][href='#{grouped_path}']"
    assert_selector "a[href='#{all_path}']"
  end
end
