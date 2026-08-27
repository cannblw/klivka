require "test_helper"

class VcardImport::DuplicateMarkerTest < ActiveSupport::TestCase
  test "marks candidates whose normalized names match an existing person" do
    candidates = [
      { "id" => 0, "name" => "  ÁDA  LOVELACE ", "entries" => [] },
      { "id" => 1, "name" => "Linus Torvalds", "entries" => [] },
      { "id" => 2, "name" => "LINUS TORVALDS", "entries" => [] },
      { "id" => 3, "name" => "Margaret Hamilton", "entries" => [] }
    ]

    marked_candidates = VcardImport::DuplicateMarker.call(user: users(:one), candidates:)

    assert marked_candidates.first.fetch("duplicate")
    assert marked_candidates.second.fetch("duplicate")
    assert marked_candidates.third.fetch("duplicate")
    assert_nil marked_candidates.fourth["duplicate"]
  end
end
