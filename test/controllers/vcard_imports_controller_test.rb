require "test_helper"

class VcardImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "vCard import requires authentication" do
    sign_out

    get new_vcard_import_url

    assert_redirected_to new_session_url
  end

  test "vCard import rejects uploads without authentication" do
    sign_out

    assert_no_difference "VcardImport.count" do
      post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }
    end

    assert_redirected_to new_session_url
  end

  test "vCard import shows the upload form" do
    get new_vcard_import_url

    assert_response :success
    assert_select "h1", "Import contacts"
    assert_select "input[type='file'][name='vcard_import[file]']"
  end

  test "a vCard upload creates a selected preview without creating friends or retaining the uploaded file" do
    assert_difference "VcardImport.count", 1 do
      assert_no_difference [ "Friend.count", "Entry.count" ] do
        post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }
      end
    end

    vcard_import = VcardImport.order(:id).last
    assert_equal users(:one), vcard_import.user
    assert_equal [ "Ada Lovelace", "Grace Hopper" ], vcard_import.candidates.pluck("name")
    assert_equal [ 0, 1 ], vcard_import.selected_candidate_ids
    assert_redirected_to vcard_import_url(vcard_import)
  end

  test "vCard import shows a validation error when no file is uploaded" do
    assert_no_difference "VcardImport.count" do
      post vcard_imports_url, params: { vcard_import: { file: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /Choose a vCard file to continue./
  end

  test "vCard import rejects a file over the configured size" do
    with_max_file_size(1) do
      assert_no_difference "VcardImport.count" do
        post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }
      end
    end

    assert_response :unprocessable_entity
    assert_select "main", /Choose a file up to 1 Byte./
  end

  test "vCard import shows only the current user's preview" do
    vcard_import = users(:two).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Bob Ross", "entries" => [] } ]
    )

    get vcard_import_url(vcard_import)

    assert_response :not_found
  end

  test "vCard import shows a selected, searchable preview with selection controls" do
    vcard_import = create_preview

    get vcard_import_url(vcard_import)

    assert_response :success
    assert_select "[data-controller~='filter-list'][data-controller~='vcard-import-preview']"
    assert_select "input[type='search'][id='vcard-import-search']"
    assert_select "input[type='checkbox'][name='vcard_import[selected_candidate_ids][]']", count: 2
    assert_select "input[type='checkbox'][checked]", count: 2
    assert_select "button[data-vcard-import-preview-target='selectAll'][disabled]", text: "Select all"
    assert_select "button[data-vcard-import-preview-target='deselectAll']:not([disabled])", text: "Deselect all"
    assert_select "[data-vcard-import-preview-target='submitWrapper'][tabindex='-1'][aria-labelledby='vcard-import-submit']"
    assert_select "button#vcard-import-submit[type='submit'][data-vcard-import-preview-target='submit']", text: "Import selected contacts"
    assert_select "#vcard-import-selection-required[role='tooltip'][data-vcard-import-preview-target='selectionHint']", text: "Select at least one contact to import."
  end

  test "vCard import marks duplicate candidates before contacts are created" do
    post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }

    vcard_import = VcardImport.order(:id).last

    assert vcard_import.candidates.first.fetch("duplicate")
    assert vcard_import.candidates.second.fetch("duplicate")
  end

  test "vCard import shows warnings for duplicate and unsupported contact details" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [ {
        "id" => 0,
        "name" => "Ada Lovelace",
        "entries" => [],
        "duplicate" => true,
        "unsupported_properties" => %w[ADR X-SOCIALPROFILE]
      } ],
      selected_candidate_ids: [ 0 ]
    )

    get vcard_import_url(vcard_import)

    assert_select "div[role='note']", count: 2
    assert_select "#vcard-import-candidate-0-details [role='note']", count: 2
  end

  test "vCard import creates the explicitly selected contacts" do
    vcard_import = create_preview

    assert_difference "Friend.count", 1 do
      assert_no_difference "Entry.count" do
        patch vcard_import_url(vcard_import), params: { vcard_import: { selected_candidate_ids: [ "1" ] } }
      end
    end

    assert_redirected_to friends_url
    assert_equal "Grace Hopper", users(:one).friends.order(:id).last.name
    assert_not VcardImport.exists?(vcard_import.id)
  end

  test "vCard import rejects a candidate from another preview" do
    vcard_import = create_preview

    patch vcard_import_url(vcard_import), params: { vcard_import: { selected_candidate_ids: [ "99" ] } }

    assert_response :unprocessable_entity
    assert_equal [ 0, 1 ], vcard_import.reload.selected_candidate_ids
  end

  test "vCard import requires at least one selected contact" do
    vcard_import = create_preview

    assert_no_difference [ "Friend.count", "Entry.count", "VcardImport.count" ] do
      patch vcard_import_url(vcard_import), params: { vcard_import: { selected_candidate_ids: [ "" ] } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /Select at least one contact\./
  end

  test "vCard import removes an expired preview instead of showing it" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      expires_at: 1.minute.ago
    )

    assert_difference "VcardImport.count", -1 do
      get vcard_import_url(vcard_import)
    end

    assert_redirected_to new_vcard_import_url
  end

  test "vCard import replaces an earlier preview after a successful re-upload" do
    previous_preview = create_preview

    assert_no_difference "VcardImport.count" do
      post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }
    end

    assert_not VcardImport.exists?(previous_preview.id)
  end

  test "vCard import limits uploads for each user" do
    Rails.cache.clear
    Rails.application.config.x.vcard_import_upload_rate_limit.times do
      post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }
    end
    post vcard_imports_url, params: { vcard_import: { file: uploaded_contacts } }

    assert_redirected_to new_vcard_import_url
    follow_redirect!
    assert_select "#flash", /Try uploading again in a little while./
  ensure
    Rails.cache.clear
  end

  private

  def create_preview
    users(:one).vcard_imports.create!(
      candidates: [
        { "id" => 0, "name" => "Ada Lovelace", "entries" => [] },
        { "id" => 1, "name" => "Grace Hopper", "entries" => [] }
      ],
      selected_candidate_ids: [ 0, 1 ]
    )
  end

  def uploaded_contacts
    fixture_file_upload("contacts.vcf", "text/vcard")
  end

  def with_max_file_size(size)
    configuration = Rails.application.config.x
    original_size = configuration.vcard_import_max_file_size_bytes
    configuration.vcard_import_max_file_size_bytes = size
    yield
  ensure
    configuration.vcard_import_max_file_size_bytes = original_size
  end
end
