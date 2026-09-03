require "test_helper"

class AccountImport::ImporterTest < ActiveSupport::TestCase
  test "restores a complete account export while preserving the destination login identity" do
    source = users(:one)
    add_complete_export_data(source)
    destination = users(:two)
    destination_session = destination.sessions.create!(user_agent: "Import test")
    original_identity = destination.attributes.slice("email_address", "password_digest", "confirmed_at", "created_at", "updated_at")
    document = export_document(source)

    AccountImport::Importer.call(user: destination, document:)

    destination.reload
    assert_equal original_identity, destination.attributes.slice(*original_identity.keys)
    assert destination.authenticate("password")
    assert destination.sessions.exists?(destination_session.id)
    assert_equal exported_relationship_data(source), exported_relationship_data(destination)
    assert_equal exported_preferences(source), exported_preferences(destination)
    assert_nil destination.reminders_scanned_through_on
  end

  test "removes temporary import state when restoring an account" do
    destination = users(:two)
    destination.vcard_imports.create!(
      candidates: [ { "id" => 1, "name" => "Temporary person", "entries" => [] } ],
      selected_candidate_ids: []
    )

    AccountImport::Importer.call(user: destination, document: export_document(users(:one)))

    assert_empty destination.vcard_imports.reload
  end

  test "rolls back every replacement when a restored record is invalid" do
    destination = users(:two)
    before_import = export_payload(destination)
    document = export_document(users(:one))
    document.payload.fetch("people").first["name"] = ""

    assert_raises ActiveRecord::RecordInvalid do
      AccountImport::Importer.call(user: destination, document:)
    end

    assert_equal before_import, export_payload(destination.reload)
  end

  private

  def add_complete_export_data(user)
    person = people(:ada)
    person.update!(category: user.categories.first)
    person.create_keep_in_touch_setting!(
      cadence: "monthly",
      enabled_on: Date.current - 2.months,
      first_reminder_on: Date.current - 1.month
    )
    person.interactions.create!(occurred_on: Date.current, note: "Caught up over lunch")
    date_entry = person.entries.create!(
      type: "Entry::Date",
      position: 3,
      entry_date: Date.current.next_year,
      content: { "label" => "Anniversary" }
    )
    date_entry.create_entry_reminder!(lead_value: 2, lead_unit: "days", recurrence: "yearly")
    person.entries.create!(
      type: "Entry::FirstMet",
      position: 4,
      entry_date: Date.new(2020, 5, 1),
      content: { "date_precision" => "month", "note" => "At a conference" }
    )
    person.entries.create!(
      type: "Entry::GiftList",
      position: 5,
      content: {
        "title" => "Ideas",
        "items" => [ { "id" => "book", "text" => "A book", "checked" => false } ]
      }
    )
    people(:grace).archive!
  end

  def export_document(user)
    AccountImport::Document.parse(JSON.generate(export_payload(user)))
  end

  def export_payload(user)
    AccountExportSerializer.new(user:, generated_at: Time.utc(2026, 9, 2, 12)).as_json
  end

  def exported_relationship_data(user)
    export_payload(user).slice("categories", "contact_methods", "people")
  end

  def exported_preferences(user)
    export_payload(user).fetch("account").except("email_address", "created_at", "updated_at")
  end
end
