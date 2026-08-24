require "test_helper"

class VcardImport::PreviewStagerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "vCard preview stager atomically replaces the user's preview and schedules its removal" do
    user = users(:one)
    previous_preview = user.vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Previous Person", "entries" => [] } ]
    )
    candidates = [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ]
    vcard_import = nil

    travel_to Time.zone.local(2026, 8, 21, 12) do
      assert_enqueued_with(job: VcardImportExpirationJob, at: 1.hour.from_now) do
        vcard_import = VcardImport::PreviewStager.call(user:, candidates:, rejected_count: 2)
      end
    end

    assert_not VcardImport.exists?(previous_preview.id)
    assert_equal candidates, vcard_import.candidates
    assert_equal 2, vcard_import.rejected_count
  end
end
