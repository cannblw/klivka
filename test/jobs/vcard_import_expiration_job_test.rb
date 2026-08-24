require "test_helper"

class VcardImportExpirationJobTest < ActiveJob::TestCase
  test "vCard import expiration job removes an expired preview" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      expires_at: 1.minute.ago
    )

    assert_difference "VcardImport.count", -1 do
      VcardImportExpirationJob.perform_now(vcard_import.id)
    end
  end

  test "vCard import expiration job keeps a preview that has not expired" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      expires_at: 1.minute.from_now
    )

    assert_no_difference "VcardImport.count" do
      VcardImportExpirationJob.perform_now(vcard_import.id)
    end
  end

  test "vCard import expiration job finishes safely when the preview no longer exists" do
    assert_nothing_raised { VcardImportExpirationJob.perform_now(-1) }
  end
end
