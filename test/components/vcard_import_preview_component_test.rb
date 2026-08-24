require "test_helper"

class VcardImportPreviewComponentTest < ViewComponent::TestCase
  test "vCard import preview component renders selected candidates and bulk controls" do
    vcard_import = VcardImport.new(
      candidates: [
        { "id" => 0, "name" => "Ada Lovelace", "entries" => [] },
        { "id" => 1, "name" => "Grace Hopper", "entries" => [] }
      ],
      selected_candidate_ids: [ 0, 1 ]
    )

    render_inline VcardImportPreviewComponent.new(vcard_import:)

    assert_selector "[data-controller~='filter-list'][data-controller~='vcard-import-preview']"
    assert_selector "form[action='/friends/import/preview'][method='post'] input[name='_method'][value='patch']", visible: :all
    assert_selector "input#vcard-import-search[type='search']"
    assert_selector "input[type='checkbox'][checked]", count: 2
    assert_selector "button[data-vcard-import-preview-target='selectAll'][disabled]"
    assert_selector "button[data-vcard-import-preview-target='deselectAll']:not([disabled])"
    assert_selector "button[data-vcard-import-preview-target='submit']:not([disabled])"
  end

  test "vCard import preview component exposes guidance when no candidate is selected" do
    vcard_import = VcardImport.new(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      selected_candidate_ids: []
    )

    render_inline VcardImportPreviewComponent.new(vcard_import:)

    assert_selector "button[data-vcard-import-preview-target='selectAll']:not([disabled])"
    assert_selector "button[data-vcard-import-preview-target='deselectAll'][disabled]"
    assert_selector "button[data-vcard-import-preview-target='submit'][disabled][aria-describedby='vcard-import-selection-required']"
    assert_selector "[data-vcard-import-preview-target='submitWrapper'][tabindex='0'][aria-describedby='vcard-import-selection-required']"
    assert_selector "#vcard-import-selection-required[role='tooltip']"
  end
end
