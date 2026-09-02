require "test_helper"

class AccountImport::DocumentTest < ActiveSupport::TestCase
  test "imports the format version currently produced by account exports" do
    assert_includes AccountImport::Document::SUPPORTED_FORMAT_VERSIONS, AccountExportSerializer::FORMAT_VERSION
    assert_equal AccountExportSerializer::ENTRY_TYPES.values.sort, AccountImport::Document::ENTRY_TYPES.keys.sort
  end

  test "accepts the complete version one export contract" do
    document = AccountImport::Document.parse(export_json)

    assert_equal users(:one).email_address, document.source_email_address
    assert_equal({
      "generated_at" => document.payload["generated_at"],
      "categories" => users(:one).categories.count,
      "contact_methods" => users(:one).contact_methods.count,
      "people" => 2,
      "archived_people" => 0,
      "entries" => 5,
      "interactions" => 0,
      "reminders" => 0
    }, document.summary)
  end

  test "rejects malformed JSON" do
    error = assert_raises(AccountImport::Document::InvalidDocument) do
      AccountImport::Document.parse("not JSON")
    end

    assert_equal :invalid_json, error.code
  end

  test "rejects an unsupported format version" do
    payload = export_payload
    payload["format_version"] = 2

    error = assert_invalid(payload)

    assert_equal :unsupported_version, error.code
  end

  test "rejects missing and unknown fields" do
    missing_field = export_payload
    missing_field["account"].delete("time_zone")
    unknown_field = export_payload
    unknown_field["people"].first["relationship_score"] = 100

    assert_equal :invalid_structure, assert_invalid(missing_field).code
    assert_equal :invalid_structure, assert_invalid(unknown_field).code
  end

  test "rejects invalid dates and timestamps" do
    invalid_date = export_payload
    invalid_date["people"].first["contact_reminder_snoozed_until"] = "2026-02-30"
    invalid_timestamp = export_payload
    invalid_timestamp["generated_at"] = "yesterday"

    assert_equal :invalid_value, assert_invalid(invalid_date).code
    assert_equal :invalid_value, assert_invalid(invalid_timestamp).code
  end

  test "rejects unsupported entry types and missing category references" do
    unsupported_entry = export_payload
    unsupported_entry["people"].first["entries"].first["type"] = "address"
    missing_category = export_payload
    missing_category["people"].first["category"] = "Not exported"

    assert_equal :unsupported_entry_type, assert_invalid(unsupported_entry).code
    assert_equal :invalid_reference, assert_invalid(missing_category).code
  end

  test "rejects duplicate normalized names and person slugs" do
    duplicate_category = export_payload
    duplicate_category["categories"] << duplicate_category["categories"].first.merge("name" => " family ")
    duplicate_slug = export_payload
    duplicate_slug["people"].last["slug"] = duplicate_slug["people"].first["slug"]

    assert_equal :duplicate_value, assert_invalid(duplicate_category).code
    assert_equal :duplicate_value, assert_invalid(duplicate_slug).code
  end

  test "rejects invalid contact methods and reminder settings" do
    invalid_contact_method = export_payload
    invalid_contact_method["contact_methods"].first["icon_name"] = "unsupported"
    invalid_reminder = export_payload
    invalid_reminder["account"]["default_reminder_lead_unit"] = "weeks"

    assert_equal :invalid_value, assert_invalid(invalid_contact_method).code
    assert_equal :invalid_value, assert_invalid(invalid_reminder).code
  end

  private

  def export_json
    JSON.generate(export_payload)
  end

  def export_payload
    AccountExportSerializer.new(user: users(:one), generated_at: Time.utc(2026, 9, 2, 12)).as_json.deep_dup
  end

  def assert_invalid(payload)
    assert_raises(AccountImport::Document::InvalidDocument) do
      AccountImport::Document.parse(JSON.generate(payload))
    end
  end
end
