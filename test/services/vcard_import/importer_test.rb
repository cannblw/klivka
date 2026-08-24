require "test_helper"

class VcardImport::ImporterTest < ActiveSupport::TestCase
  test "vCard importer creates selected friends and their optional entries, then removes the preview" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [
        {
          "id" => 0,
          "name" => "Ada Lovelace",
          "entries" => [
            { "type" => "Entry::Phone", "content" => { "number" => "+44 20 1234", "label" => "mobile" } },
            { "type" => "Entry::Birthday", "entry_date" => "1815-12-10" }
          ]
        },
        { "id" => 1, "name" => "Grace Hopper", "entries" => [] }
      ]
    )

    assert_difference "Friend.count", 1 do
      assert_difference "Entry.count", 2 do
        VcardImport::Importer.call(vcard_import:, selected_candidate_ids: [ 0 ])
      end
    end

    friend = users(:one).friends.order(:id).last
    assert_equal "Ada Lovelace", friend.name
    assert_equal [ "Entry::Phone", "Entry::Birthday" ], friend.entries.order(:position).pluck(:type)
    assert_not VcardImport.exists?(vcard_import.id)
  end

  test "vCard importer does not create contacts when the selection is invalid" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ]
    )

    assert_no_difference [ "Friend.count", "Entry.count", "VcardImport.count" ] do
      assert_raises ActiveRecord::RecordInvalid do
        VcardImport::Importer.call(vcard_import:, selected_candidate_ids: [ 1 ])
      end
    end

    assert_equal [], vcard_import.reload.selected_candidate_ids
  end

  test "vCard importer rolls back every contact when an entry cannot be imported" do
    vcard_import = users(:one).vcard_imports.create!(
      candidates: [
        { "id" => 0, "name" => "Ada Lovelace", "entries" => [] },
        {
          "id" => 1,
          "name" => "Grace Hopper",
          "entries" => [ { "type" => "Entry::Email", "content" => { "email" => "invalid" } } ]
        }
      ]
    )

    assert_no_difference [ "Friend.count", "Entry.count", "VcardImport.count" ] do
      assert_raises ActiveRecord::RecordInvalid do
        VcardImport::Importer.call(vcard_import:, selected_candidate_ids: [ 0, 1 ])
      end
    end

    assert_equal [], vcard_import.reload.selected_candidate_ids
  end
end
