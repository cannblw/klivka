require "application_system_test_case"

class PeopleFiltersTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:one)
  end

  test "filters survive Turbo navigation, refresh, and browser history" do
    assert_no_selector "select[name='birthday']", visible: true
    find("summary", text: "More options").click
    select "Recently updated", from: "Sort people"
    assert_text "Ada Lovelace"
    assert_equal "recently_updated", current_query.fetch("sort")

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
    assert_current_path(/has_blocks/)
    assert_equal [ "note" ], current_query.fetch("has_blocks")
    assert_equal [ "email" ], current_query.fetch("missing_blocks")

    page.go_back
    assert_no_current_path(/has_blocks/)
    assert_checked_field "missing-blocks-email"
    assert_unchecked_field "has-blocks-note"
    assert_text "Grace Hopper"

    click_button "Clear filters"
    assert_text "Ada Lovelace"
    assert_text "Grace Hopper"
    assert_equal({ "sort" => "recently_updated" }, current_query)
  end

  test "people actions are discoverable and the menu returns focus on Escape" do
    click_button "More actions"

    assert_button "Add several people", visible: true
    assert_link "Import contacts", visible: true
    assert_link "Archived people", visible: true

    find_button("More actions").send_keys(:escape)

    assert_no_button "Add several people", visible: true
    assert_includes page.evaluate_script("document.activeElement.innerText"), "More actions"
  end

  test "adding several people does not persist modal or menu state in browser history" do
    click_button "More actions"
    click_button "Add several people"

    assert_selector "dialog[open]"
    assert_no_current_path(/batch=true/)

    within("dialog") { click_button "Cancel" }
    click_button "More actions"
    click_link "Archived people"
    page.go_back

    assert_no_selector "dialog[open]"
    assert_no_button "Add several people", visible: true
    assert_no_current_path(/batch=true/)
  end

  test "the people view choice survives Turbo navigation and browser history" do
    people(:ada).update!(category: categories(:family))
    page.refresh

    within("nav[aria-label='People view']") do
      click_link "All people"
    end

    assert_current_path root_path(view: "all")
    assert_equal "all", current_query.fetch("view")
    assert_selector "nav[aria-label='People view'] a[aria-current='true']", text: "All people"

    page.go_back

    assert_no_current_path(/view=all/)
    assert_selector "nav[aria-label='People view'] a[aria-current='true']", text: "Grouped"
  end

  private

  def current_query
    Rack::Utils.parse_nested_query(URI.parse(page.current_url).query.to_s)
  end
end
