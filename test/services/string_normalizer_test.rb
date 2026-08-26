require "test_helper"

class StringNormalizerTest < ActiveSupport::TestCase
  test "string normalization canonicalizes Unicode and whitespace without changing natural text" do
    normalized = StringNormalizer.call("  Caf\u0065\u0301\u00A0\u00A0Friends  ")

    assert_equal "Caf\u00E9 Friends", normalized
  end

  test "string normalization returns an empty string for a missing value" do
    assert_equal "", StringNormalizer.call(nil)
  end
end
