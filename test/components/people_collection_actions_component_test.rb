require "test_helper"

class PeopleCollectionActionsComponentTest < ViewComponent::TestCase
  test "keeps name-only creation primary and groups secondary actions" do
    routes = Rails.application.routes.url_helpers

    render_inline PeopleCollectionActionsComponent.new(demo_mode: false)

    assert_button "Add someone"
    assert_selector "#people-collection-actions-trigger[aria-expanded='false']", text: "More actions"
    assert_selector "#people-collection-actions-dropdown.hidden" do
      assert_button "Add several people"
      assert_link "Import contacts", href: routes.new_vcard_import_path
      assert_link "Archived people", href: routes.archived_people_path
    end
  end

  test "keeps importing unavailable in the shared demo" do
    render_inline PeopleCollectionActionsComponent.new(demo_mode: true)

    assert_no_link "Import contacts"
    assert_button "Add several people"
    assert_link "Archived people"
  end
end
