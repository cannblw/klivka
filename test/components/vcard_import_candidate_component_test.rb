require "test_helper"

class VcardImportCandidateComponentTest < ViewComponent::TestCase
  test "vCard candidate component renders a selectable contact with supported details" do
    candidate = {
      "id" => 4,
      "name" => "Ada Lovelace",
      "entries" => [
        { "type" => "Entry::Phone", "content" => { "number" => "+44 20 1234", "label" => "mobile" } },
        { "type" => "Entry::Birthday", "entry_date" => "1815-12-10" }
      ]
    }

    render_inline VcardImportCandidateComponent.new(candidate:, selected_candidate_ids: [ 4 ])

    assert_selector "li[data-filter-list-target='item'][data-search-value*='Ada Lovelace']"
    assert_selector "input[type='checkbox'][name='vcard_import[selected_candidate_ids][]'][value='4'][checked][aria-describedby='vcard-import-candidate-4-details']"
    assert_selector "label[for='vcard-import-candidate-4'] .sr-only", text: "Ada Lovelace"
    assert_selector "#vcard-import-candidate-4-details"
    assert_text "Phone: mobile: +44 20 1234"
    assert_text "Birthday: December 10, 1815"
  end

  test "vCard candidate component identifies duplicate contacts and unsupported information" do
    candidate = {
      "id" => 4,
      "name" => "Ada Lovelace",
      "entries" => [],
      "duplicate" => true,
      "unsupported_properties" => %w[ADR X-SOCIALPROFILE]
    }

    render_inline VcardImportCandidateComponent.new(candidate:)

    assert_selector "#vcard-import-candidate-4-details [role='note']", count: 2
  end
end
