require "test_helper"

class AccountExportSerializerTest < ActiveSupport::TestCase
  test "exports the complete version one account contract" do
    travel_to Time.utc(2026, 9, 2, 12, 34, 56) do
      user = build_account
      export = AccountExportSerializer.new(user:, generated_at: Time.current).as_json

      assert_equal %w[format_version generated_at account categories contact_methods people], export.keys
      assert_equal 1, export["format_version"]
      assert_equal "2026-09-02T12:34:56.000000Z", export["generated_at"]
      assert_equal expected_account(user), export["account"]

      category = user.categories.sole
      assert_equal({
        "id" => category.id,
        "name" => "Family",
        "created_at" => exported_time(category.created_at),
        "updated_at" => exported_time(category.updated_at)
      }, export["categories"].sole)

      contact_method = user.contact_methods.sole
      assert_equal({
        "id" => contact_method.id,
        "name" => "Carrier pigeon",
        "icon_library" => "material_icons",
        "icon_name" => "more_horiz",
        "enabled" => true,
        "provided" => false,
        "position" => 0,
        "created_at" => exported_time(contact_method.created_at),
        "updated_at" => exported_time(contact_method.updated_at)
      }, export["contact_methods"].sole)

      person = user.people.sole
      person_export = export["people"].sole
      assert_equal expected_person(person), person_export.except("keep_in_touch_setting", "entries", "interactions")
      assert_equal expected_keep_in_touch_setting(person.keep_in_touch_setting), person_export["keep_in_touch_setting"]
      assert_equal %w[phone note birthday email date first_met gift_list], person_export["entries"].pluck("type")
      assert_equal person.entries.order(:position).pluck(:id), person_export["entries"].pluck("id")
      assert_entry_contract(person_export["entries"], person)
      assert_equal [ expected_interaction(person.interactions.sole) ], person_export["interactions"]
    end
  end

  test "keeps another account and internal state out of the export" do
    user = users(:one)
    export = AccountExportSerializer.new(user:).as_json
    serialized = export.to_json

    assert_not_includes serialized, users(:two).email_address
    assert_not_includes export["people"].pluck("id"), people(:bob).id
    assert_empty export.keys & %w[sessions vcard_imports reminder_deliveries contact_reminder_digests]
    assert_empty export["account"].keys & %w[password_digest confirmed_at reminders_scanned_through_on]
    assert export["categories"].all? { |category| !category.key?("normalized_name") }
    assert export["contact_methods"].all? { |contact_method| !contact_method.key?("normalized_name") }
  end

  test "orders exported collections deterministically" do
    user = build_account
    person = user.people.sole
    first_entry = person.entries.first
    first_entry.update_column(:position, 20)
    later_person = user.people.create!(name: "Later person")
    earlier_person = user.people.create!(name: "Earlier alphabetically")

    export = AccountExportSerializer.new(user:).as_json

    assert_equal [ person.id, later_person.id, earlier_person.id ], export["people"].pluck("id")
    assert_equal first_entry.id, export["people"].first["entries"].last["id"]
    assert_equal user.categories.order(:id).pluck(:id), export["categories"].pluck("id")
    assert_equal user.contact_methods.order(:id).pluck(:id), export["contact_methods"].pluck("id")
  end

  private

  def build_account
    user = User.create!(
      email_address: "export@example.com",
      password: "a-safe-password",
      locale: "es",
      theme: "dark",
      time_zone: "Europe/Madrid",
      reminder_in_app_enabled: false,
      reminder_email_enabled: true,
      default_reminder_lead_value: 3,
      default_reminder_lead_unit: "days",
      birthday_reminders_enabled: false,
      birthday_reminder_lead_value: 2,
      birthday_reminder_lead_unit: "months",
      contact_reminder_cadence: "weekly",
      contact_reminders_enabled_on: Date.new(2026, 9, 2),
      contact_reminder_first_reminder_on: Date.new(2026, 9, 8)
    )
    user.contact_methods.delete_all
    category = user.categories.create!(name: "Family")
    user.contact_methods.create!(
      name: "Carrier pigeon",
      icon_library: "material_icons",
      icon_name: "more_horiz",
      enabled: true,
      provided: false,
      position: 0
    )
    person = user.people.create!(
      name: "Archived person",
      category:,
      archived_at: Time.current,
      contact_reminder_snoozed_until: Date.new(2026, 9, 9)
    )
    person.create_keep_in_touch_setting!(
      cadence: "monthly",
      enabled_on: Date.new(2026, 9, 2),
      first_reminder_on: Date.new(2026, 10, 2)
    )

    entries = [
      [ Entry::Phone, { "number" => "+44 20 1234 5678" }, nil, nil ],
      [ Entry::Note, { "text" => "Remember this" }, nil, nil ],
      [ Entry::Birthday, {}, Date.new(1980, 2, 29), true ],
      [ Entry::Email, { "email" => "person@example.com", "label" => "Home" }, nil, nil ],
      [ Entry::Date, { "label" => "Anniversary" }, Date.new(2027, 4, 5), nil ],
      [ Entry::FirstMet, { "note" => "At a concert", "date_precision" => "month" }, Date.new(2019, 6, 1), nil ],
      [ Entry::GiftList, { "title" => "Ideas", "items" => [ { "id" => "gift-1", "text" => "Book", "checked" => false } ] }, nil, nil ]
    ]
    entries.each_with_index do |(type, content, entry_date, birthday_year_known), position|
      person.entries.create!(type: type.name, content:, entry_date:, birthday_year_known:, position:)
    end
    person.entries.find_by!(type: "Entry::Date").create_entry_reminder!(
      lead_value: 5,
      lead_unit: "days",
      recurrence: "yearly"
    )
    person.interactions.create!(
      occurred_on: Date.new(2026, 8, 30),
      contact_method_name: "Carrier pigeon",
      contact_method_icon_library: "material_icons",
      contact_method_icon_name: "more_horiz",
      note: "Made plans"
    )
    user
  end

  def expected_account(user)
    {
      "id" => user.id,
      "email_address" => "export@example.com",
      "locale" => "es",
      "theme" => "dark",
      "time_zone" => "Europe/Madrid",
      "reminder_in_app_enabled" => false,
      "reminder_email_enabled" => true,
      "default_reminder_lead_value" => 3,
      "default_reminder_lead_unit" => "days",
      "birthday_reminders_enabled" => false,
      "birthday_reminder_lead_value" => 2,
      "birthday_reminder_lead_unit" => "months",
      "contact_reminder_cadence" => "weekly",
      "contact_reminders_enabled_on" => "2026-09-02",
      "contact_reminder_first_reminder_on" => "2026-09-08",
      "created_at" => exported_time(user.created_at),
      "updated_at" => exported_time(user.updated_at)
    }
  end

  def expected_person(person)
    {
      "id" => person.id,
      "name" => "Archived person",
      "slug" => "archived-person",
      "category_id" => person.category_id,
      "archived_at" => exported_time(person.archived_at),
      "contact_reminder_snoozed_until" => "2026-09-09",
      "created_at" => exported_time(person.created_at),
      "updated_at" => exported_time(person.updated_at)
    }
  end

  def expected_keep_in_touch_setting(setting)
    {
      "id" => setting.id,
      "cadence" => "monthly",
      "enabled_on" => "2026-09-02",
      "first_reminder_on" => "2026-10-02",
      "created_at" => exported_time(setting.created_at),
      "updated_at" => exported_time(setting.updated_at)
    }
  end

  def assert_entry_contract(entries, person)
    expected_keys = %w[id type position content entry_date birthday_year_known created_at updated_at reminder]
    assert entries.all? { |entry| entry.keys == expected_keys }

    birthday = entries.find { |entry| entry["type"] == "birthday" }
    assert_equal "1980-02-29", birthday["entry_date"]
    assert_equal true, birthday["birthday_year_known"]

    gift_list = entries.find { |entry| entry["type"] == "gift_list" }
    assert_equal [ { "id" => "gift-1", "text" => "Book", "checked" => false } ], gift_list.dig("content", "items")

    date = entries.find { |entry| entry["type"] == "date" }
    reminder = person.entries.find(date["id"]).entry_reminder
    assert_equal({
      "id" => reminder.id,
      "lead_value" => 5,
      "lead_unit" => "days",
      "recurrence" => "yearly",
      "created_at" => exported_time(reminder.created_at),
      "updated_at" => exported_time(reminder.updated_at)
    }, date["reminder"])
    assert entries.excluding(date).all? { |entry| entry["reminder"].nil? }
  end

  def expected_interaction(interaction)
    {
      "id" => interaction.id,
      "occurred_on" => "2026-08-30",
      "contact_method_name" => "Carrier pigeon",
      "contact_method_icon_library" => "material_icons",
      "contact_method_icon_name" => "more_horiz",
      "note" => "Made plans",
      "created_at" => exported_time(interaction.created_at),
      "updated_at" => exported_time(interaction.updated_at)
    }
  end

  def exported_time(value)
    value.utc.iso8601(6)
  end
end
