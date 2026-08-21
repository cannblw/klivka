require "test_helper"

class VcardImportTest < ActiveSupport::TestCase
  test "belongs to its user and removes expired previews" do
    import = users(:one).vcard_imports.create!(
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      selected_candidate_ids: [],
      expires_at: 1.minute.ago
    )

    assert import.expired?
    assert_equal [ import ], VcardImport.expired.to_a
  end

  test "rejects a negative rejected count" do
    import = VcardImport.new(
      user: users(:one),
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      selected_candidate_ids: [],
      rejected_count: -1,
      expires_at: 1.hour.from_now
    )

    assert_not import.valid?
    assert import.errors.of_kind?(:rejected_count, :greater_than_or_equal_to)
  end

  test "rejects malformed candidate state and selection ids" do
    import = VcardImport.new(
      user: users(:one),
      candidates: [ { "id" => 0, "name" => "Ada Lovelace", "entries" => [] } ],
      selected_candidate_ids: [ 0, 0, 99 ],
      expires_at: 1.hour.from_now
    )

    assert_not import.valid?
    assert import.errors.of_kind?(:selected_candidate_ids, :invalid)

    import.candidates = "not an array"
    import.selected_candidate_ids = []

    assert_not import.valid?
    assert import.errors.of_kind?(:candidates, :invalid)
  end

  test "starts with JSON-safe empty selection state" do
    travel_to Time.zone.local(2026, 8, 21, 12) do
      import = VcardImport.new

      assert_equal [], import.candidates
      assert_equal [], import.selected_candidate_ids
      assert_equal 1.hour.from_now, import.expires_at
    end
  end

  test "rejects staged entries with unsupported types" do
    import = VcardImport.new(
      user: users(:one),
      candidates: [ {
        "id" => 0,
        "name" => "Ada Lovelace",
        "entries" => [ { "type" => "Entry::GiftList", "content" => {} } ]
      } ]
    )

    assert_not import.valid?
    assert import.errors.of_kind?(:candidates, :invalid)
  end
end
