require "test_helper"

class PeopleQueryControlsComponentTest < ViewComponent::TestCase
  test "renders every query control with default values omitted" do
    search = PeopleQuery.new(users(:one), nil)

    render_inline PeopleQueryControlsComponent.new(
      search:,
      categories: users(:one).categories.order(:normalized_name),
      view: "grouped",
      grouping_available: false
    )

    assert_selector "section[aria-label='Search and sort people']"
    assert_selector "form[data-controller='search'][data-turbo-frame='people_grid'][data-turbo-action='advance']"
    assert_selector "input[name='view'][value='']", visible: false
    assert_selector "input[type='search'][name='query']"
    assert_selector "select[name='sort']", visible: false
    %w[birthday last_contact category state contact_reminder date_reminder].each do |filter|
      assert_selector "select[name='#{filter}']", visible: false
    end
    assert_selector "fieldset", count: 2, visible: false
    assert_selector "input[type='checkbox'][name='has_blocks[]']", count: PeopleQuery::BLOCK_TYPES.size, visible: false
    assert_selector "input[type='checkbox'][name='missing_blocks[]']", count: PeopleQuery::BLOCK_TYPES.size, visible: false
    assert_selector "details:not([open]) summary", text: "More options"
    assert_selector "button[data-search-target='clear'][hidden]", text: "Clear filters", visible: false
  end

  test "restores selected filters and exposes the clear action" do
    search = PeopleQuery.new(
      users(:one),
      "ada",
      sort: "recently_updated",
      filters: {
        birthday: "missing",
        category: categories(:family).id,
        state: "all",
        has_blocks: %w[email birthday],
        missing_blocks: [ "gift_list" ],
        contact_reminder: "on",
        date_reminder: "missing"
      }
    )

    render_inline PeopleQueryControlsComponent.new(
      search:,
      categories: users(:one).categories.order(:normalized_name),
      view: "all",
      grouping_available: true
    )

    assert_selector "input[name='view'][value='all']", visible: false
    assert_selector "input[name='query'][value='ada']"
    assert_selector "select[name='sort'] option[selected][value='recently_updated']"
    assert_selector "select[name='birthday'] option[selected][value='missing']"
    assert_selector "select[name='category'] option[selected][value='#{categories(:family).id}']"
    assert_selector "select[name='state'] option[selected][value='all']"
    assert_selector "select[name='contact_reminder'] option[selected][value='on']"
    assert_selector "select[name='date_reminder'] option[selected][value='missing']"
    assert_selector "input[name='has_blocks[]'][value='email'][checked]"
    assert_selector "input[name='has_blocks[]'][value='birthday'][checked]"
    assert_selector "input[name='missing_blocks[]'][value='gift_list'][checked]"
    assert_selector "details[open] summary" do
      assert_text "More options"
      assert_text "Options on"
    end

    assert_selector "button[data-search-target='clear'][data-action='search#clearFilters']:not([hidden])", text: "Clear filters"
  end

  test "keeps sorting with occasional people-finding options" do
    search = PeopleQuery.new(users(:one), nil, sort: "recently_contacted")

    render_inline PeopleQueryControlsComponent.new(
      search:,
      categories: users(:one).categories.order(:normalized_name),
      view: "grouped",
      grouping_available: false
    )

    assert_selector "details[open] select[name='sort'][data-search-target='option']" do
      assert_selector "option[value='recently_contacted'][selected]"
      assert_selector "option[value='least_recently_contacted']"
    end
  end

  test "lists only categories owned by the current user" do
    search = PeopleQuery.new(users(:one), nil)

    render_inline PeopleQueryControlsComponent.new(
      search:,
      categories: users(:one).categories.order(:normalized_name),
      view: "grouped",
      grouping_available: false
    )

    assert_selector "select[name='category'] option[value='#{categories(:family).id}']", visible: false
    assert_no_selector "select[name='category'] option[value='#{categories(:family_for_user_two).id}']", visible: false
  end

  test "places the people view choice with otherwise quiet query controls" do
    search = PeopleQuery.new(users(:one), nil)

    render_inline PeopleQueryControlsComponent.new(
      search:,
      categories: users(:one).categories.order(:normalized_name),
      view: "grouped",
      grouping_available: true
    )

    assert_selector "form nav[aria-label='People view']"
    assert_selector "form a[aria-current='true'][href='#{Rails.application.routes.url_helpers.root_path}']", text: "Grouped"
  end
end
