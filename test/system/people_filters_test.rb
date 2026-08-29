require "application_system_test_case"

class PeopleFiltersTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
  end

  test "filters survive Turbo navigation, refresh, and browser history" do
    assert_no_selector "select[name='birthday']", visible: true
    select "Recently updated", from: "Sort people"
    assert_text "Ada Lovelace"
    assert_equal "recently_updated", current_query.fetch("sort")

    find("summary", text: "Advanced search").click
    assert_selector "select[name='birthday']", visible: true
    find("#missing-blocks-email").check

    assert_text "Grace Hopper"
    assert_no_text "Ada Lovelace"
    assert_equal [ "email" ], current_query.fetch("missing_blocks")
    assert_button "Clear filters"

    page.refresh
    assert_checked_field "missing-blocks-email"
    assert_text "Grace Hopper"

    find("#has-blocks-note").check
    assert_text "Grace Hopper"
    assert_equal [ "note" ], current_query.fetch("has_blocks")
    assert_equal [ "email" ], current_query.fetch("missing_blocks")

    page.go_back
    assert_checked_field "missing-blocks-email"
    assert_unchecked_field "has-blocks-note"
    assert_text "Grace Hopper"

    click_button "Clear filters"
    assert_text "Ada Lovelace"
    assert_text "Grace Hopper"
    assert_equal({ "sort" => "recently_updated" }, current_query)
  end

  private

  def current_query
    Rack::Utils.parse_nested_query(URI.parse(page.current_url).query.to_s)
  end
end
