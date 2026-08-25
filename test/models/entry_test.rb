require "test_helper"

# == Schema Information
#
# Table name: entries
#
#  id                  :integer          not null, primary key
#  birthday_year_known :boolean
#  content             :json
#  entry_date          :date
#  position            :integer          default(0), not null
#  type                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  friend_id           :integer          not null
#
# Indexes
#
#  index_entries_on_entry_date               (entry_date)
#  index_entries_on_friend_id                (friend_id)
#  index_entries_on_friend_id_and_position   (friend_id,position)
#  index_entries_on_friend_id_for_birthday   (friend_id) UNIQUE WHERE type = 'Entry::Birthday'
#  index_entries_on_friend_id_for_first_met  (friend_id) UNIQUE WHERE type = 'Entry::FirstMet'
#
# Foreign Keys
#
#  friend_id  (friend_id => friends.id)
#
class EntryTest < ActiveSupport::TestCase
  test "every allowed entry type resolves to its STI class" do
    assert_equal Entry::CREATABLE_TYPES, Entry::CREATABLE_TYPES.filter_map { |type| Entry.creatable_type(type)&.name }
  end

  test "every creatable entry type declares its vCard import policy" do
    properties = Entry::CREATABLE_TYPES.map { |type| Entry.creatable_type(type).vcard_import_property }

    assert_not_includes properties, Entry::UNCONFIGURED_VCARD_IMPORT_PROPERTY
    assert_equal Entry.vcard_importable_types.size, Entry.vcard_importable_types.map(&:vcard_import_property).uniq.size
  end

  test "reports the entry types vCard can import" do
    assert_equal [ Entry::Phone, Entry::Note, Entry::Birthday, Entry::Email, Entry::Date ], Entry.vcard_importable_types
  end

  test "finds the importable entry type for a vCard property" do
    assert_equal Entry::Phone, Entry.vcard_importable_type_for(:tel)
    assert_equal Entry::Date, Entry.vcard_importable_type_for("anniversary")
    assert_nil Entry.vcard_importable_type_for(:url)
  end

  test "position cannot be negative" do
    entry = Entry::Note.new(friend: friends(:ada), position: -1, content: { text: "A note" })

    assert_not entry.valid?
    assert_includes entry.errors[:position], "must be greater than or equal to 0"
  end

  test "database rejects a negative position" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Entry.transaction(requires_new: true) do
        Entry.insert_all!([ {
          friend_id: friends(:ada).id,
          type: "Entry::Note",
          position: -1,
          content: { text: "A note" },
          created_at: timestamp,
          updated_at: timestamp
        } ])
      end
    end
  end

  test "instantiates STI subclasses by type" do
    phone = Entry::Phone.new(friend: friends(:ada))
    assert_instance_of Entry::Phone, phone
    assert_equal "Entry::Phone", phone.type
  end

  test "email exposes normalized email and optional label" do
    email = Entry::Email.new(friend: friends(:ada), content: { email: "  ADA@EXAMPLE.COM ", label: " Work " })

    assert email.valid?
    assert_equal "ada@example.com", email.email
    assert_equal "Work", email.label
  end

  test "email requires a valid email" do
    email = Entry::Email.new(friend: friends(:ada), content: { email: "not-an-email" })

    assert_not email.valid?
    assert email.errors.of_kind?(:email, :invalid)
  end

  test "email reports only the presence error when blank" do
    email = Entry::Email.new(friend: friends(:ada), content: { email: "" })

    assert_not email.valid?
    assert email.errors.of_kind?(:email, :blank)
    assert_not email.errors.of_kind?(:email, :invalid)
  end

  test "queries return typed objects" do
    assert_instance_of Entry::Phone, entries(:phone)
    assert_instance_of Entry::Note, entries(:note)
    assert_instance_of Entry::Birthday, entries(:ada_birthday)
    assert_instance_of Entry::Email, entries(:email)
  end

  test "birthday is a date entry" do
    assert_operator Entry::Birthday, :<, Entry::Date
    assert_kind_of Entry::Date, entries(:ada_birthday)
  end

  test "birthday validates entry_date presence" do
    birthday = Entry::Birthday.new(friend: friends(:ada), entry_date: nil)

    assert_not birthday.valid?
    assert birthday.errors.of_kind?(:entry_date, :blank)
  end

  test "birthday enforces one per friend" do
    duplicate = Entry::Birthday.new(friend: friends(:ada), entry_date: Date.current)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:friend_id, :taken)
    assert_includes duplicate.errors[:friend_id], "already has a birthday"
  end

  test "date validates entry_date presence" do
    date_entry = Entry::Date.new(friend: friends(:ada), entry_date: nil)

    assert_not date_entry.valid?
    assert date_entry.errors.of_kind?(:entry_date, :blank)
  end

  test "a date has one annual occurrence in every year" do
    date_entry = Entry::Date.new(friend: friends(:ada), entry_date: Date.new(2020, 8, 10))

    assert_equal Date.new(2026, 8, 10), date_entry.occurrence_on(year: 2026)
    assert_equal Date.new(2027, 8, 10), date_entry.next_occurrence_on(on: Date.new(2026, 8, 11))
  end

  test "a leap-day date occurs on February 28 in a non-leap year" do
    date_entry = Entry::Date.new(friend: friends(:ada), entry_date: Date.new(2020, 2, 29))

    assert_equal Date.new(2024, 2, 29), date_entry.occurrence_on(year: 2024)
    assert_equal Date.new(2025, 2, 28), date_entry.occurrence_on(year: 2025)
  end

  test "generic dates are creatable and normalize their optional label" do
    date_entry = Entry::Date.new(
      friend: friends(:ada),
      entry_date: Date.new(2020, 1, 2),
      content: { label: "  Dad's first iguana  " }
    )

    assert_equal Entry::Date, Entry.creatable_type("Entry::Date")
    assert date_entry.valid?
    assert_equal "Dad's first iguana", date_entry.label
  end

  test "date-bearing entry types require a date in the database" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Entry.transaction(requires_new: true) do
        Entry.insert_all!([ {
          friend_id: friends(:ada).id,
          type: "Entry::Date",
          entry_date: nil,
          position: 99,
          content: {},
          created_at: timestamp,
          updated_at: timestamp
        } ])
      end
    end
  end

  test "non-date entry types reject a date in the model" do
    note = Entry::Note.new(
      friend: friends(:ada),
      entry_date: Date.current,
      content: { text: "A note" }
    )

    assert_not note.valid?
    assert note.errors.of_kind?(:entry_date, :present)
  end

  test "non-date entry types reject a date in the database" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Entry.transaction(requires_new: true) do
        Entry.insert_all!([ {
          friend_id: friends(:ada).id,
          type: "Entry::Note",
          entry_date: Date.current,
          position: 99,
          content: { text: "A note" },
          created_at: timestamp,
          updated_at: timestamp
        } ])
      end
    end
  end

  test "first met accepts a full date and an optional normalized note" do
    first_met = Entry::FirstMet.new(
      friend: friends(:ada),
      entry_date: Date.new(2020, 1, 2),
      content: { note: "  At the market  " }
    )

    assert first_met.valid?
    assert_equal "At the market", first_met.note
    assert_equal "day", first_met.date_precision
  end

  test "first met accepts a year without inventing a month or day" do
    first_met = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019")

    assert first_met.valid?
    assert_equal Date.new(2019, 1, 1), first_met.entry_date
    assert_equal "year", first_met.date_precision
  end

  test "first met accepts a month and year without inventing a day" do
    first_met = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019", entry_month: "5")

    assert first_met.valid?
    assert_equal Date.new(2019, 5, 1), first_met.entry_date
    assert_equal "month", first_met.date_precision
  end

  test "first met reports elapsed years according to its date precision" do
    assert_equal 7, Entry::FirstMet.new(
      entry_date: Date.new(2019, 8, 1),
      content: { "date_precision" => "month" }
    ).years_ago(on: Date.new(2026, 8, 3))

    assert_equal 6, Entry::FirstMet.new(
      entry_date: Date.new(2019, 8, 2),
      content: { "date_precision" => "day" }
    ).years_ago(on: Date.new(2026, 8, 1))
  end

  test "first met rejects a day without a month" do
    first_met = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019", entry_day: "12")

    assert_not first_met.valid?
    assert first_met.errors.of_kind?(:entry_date, :invalid)
  end

  test "first met rejects malformed numeric date parts instead of truncating them" do
    first_met = Entry::FirstMet.new(friend: friends(:ada), entry_year: "2019.5")

    assert_not first_met.valid?
    assert first_met.errors.of_kind?(:entry_date, :invalid)
  end

  test "first met enforces one per friend" do
    Entry::FirstMet.create!(friend: friends(:ada), entry_date: Date.current)
    duplicate = Entry::FirstMet.new(friend: friends(:ada), entry_date: Date.current)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:friend_id, :taken)
  end

  test "gift list normalizes items and generates missing ids" do
    gift_list = Entry::GiftList.new(
      friend: friends(:ada),
      content: {
        title: "  Birthday ideas ",
        items: [ { text: "  A book ", checked: "1" } ]
      }
    )

    assert gift_list.valid?
    assert_equal "Birthday ideas", gift_list.title
    assert_equal "A book", gift_list.items.first["text"]
    assert_equal true, gift_list.items.first["checked"]
    assert gift_list.items.first["id"].present?
  end

  test "gift list preserves unique ids and replaces duplicate ids" do
    gift_list = Entry::GiftList.new(
      friend: friends(:ada),
      content: {
        items: [
          { id: "idea-1", text: "A book" },
          { id: "idea-1", text: "A plant" }
        ]
      }
    )

    assert gift_list.valid?
    assert_equal "idea-1", gift_list.items.first["id"]
    assert_not_equal gift_list.items.first["id"], gift_list.items.second["id"]
    assert_equal false, gift_list.items.first["checked"]
    assert_equal false, gift_list.items.second["checked"]

    normalized_ids = gift_list.items.pluck("id")
    assert gift_list.valid?
    assert_equal normalized_ids, gift_list.items.pluck("id")
  end

  test "gift list filters blank items" do
    gift_list = Entry::GiftList.new(
      friend: friends(:ada),
      content: { items: [ { text: "A book" }, { text: " " } ] }
    )

    assert gift_list.valid?
    assert_equal [ "A book" ], gift_list.items.pluck("text")
  end

  test "gift list requires at least one item" do
    gift_list = Entry::GiftList.new(friend: friends(:ada), content: { items: [] })

    assert_not gift_list.valid?
    assert gift_list.errors.of_kind?(:items, :blank)
  end

  test "age returns years after birthday has passed this year" do
    travel_to Date.new(2026, 12, 31) do
      assert_equal 211, entries(:ada_birthday).age
    end
  end

  test "age subtracts one before birthday has occurred this year" do
    travel_to Date.new(2026, 7, 28) do
      assert_equal 210, entries(:ada_birthday).age
    end
  end

  test "age is correct on the birthday itself" do
    travel_to Date.new(2026, 12, 10) do
      assert_equal 211, entries(:ada_birthday).age
    end
  end

  test "age returns nil without entry_date" do
    birthday = Entry::Birthday.new(friend: friends(:ada), entry_date: nil)

    assert_nil birthday.age
  end

  test "age accepts an on: parameter" do
    assert_equal 200, entries(:ada_birthday).age(on: Date.new(2015, 12, 10))
  end

  test "birthday accepts a month and day without a year" do
    birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "3", entry_day: "3")

    assert birthday.valid?
    assert_equal Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, 3, 3), birthday.entry_date
    assert_not birthday.birthday_year_known?
    assert_nil birthday.entry_year
    assert_nil birthday.age(on: Date.new(2026, 3, 3))
  end

  test "birthday accepts a month day and year" do
    birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "3", entry_day: "3", entry_year: "1983")

    assert birthday.valid?
    assert_equal Date.new(1983, 3, 3), birthday.entry_date
    assert birthday.birthday_year_known?
  end

  test "birthday calculates the year from current age after this year's birthday" do
    travel_to Date.new(2026, 8, 25) do
      birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "3", entry_day: "3", current_age: "43")

      assert birthday.valid?
      assert_equal Date.new(1983, 3, 3), birthday.entry_date
      assert birthday.birthday_year_known?
    end
  end

  test "birthday calculates the year from current age before this year's birthday" do
    travel_to Date.new(2026, 2, 25) do
      birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "3", entry_day: "3", current_age: "42")

      assert birthday.valid?
      assert_equal Date.new(1983, 3, 3), birthday.entry_date
    end
  end

  test "birthday current age uses the observed leap-day birthday" do
    travel_to Date.new(2025, 2, 28) do
      birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "2", entry_day: "29", current_age: "25")

      assert birthday.valid?
      assert_equal Date.new(2000, 2, 29), birthday.entry_date
      assert_equal 25, birthday.age
    end
  end

  test "birthday accepts a matching year and current age together" do
    birthday = Entry::Birthday.new(
      friend: friends(:bob), entry_month: "3", entry_day: "3", entry_year: "1983", current_age: "43"
    )

    assert birthday.valid?
    assert_equal Date.new(1983, 3, 3), birthday.entry_date
  end

  test "birthday rejects a year and current age that disagree" do
    birthday = Entry::Birthday.new(
      friend: friends(:bob), entry_month: "3", entry_day: "3", entry_year: "1983", current_age: "42"
    )

    assert_not birthday.valid?
    assert birthday.errors.of_kind?(:entry_date, :invalid)
  end

  test "birthday uses the selected year basis when the submitted age is stale" do
    travel_to Date.new(2026, 8, 25) do
      birthday = Entry::Birthday.new(
        friend: friends(:bob), entry_month: "9", entry_day: "3", entry_year: "1983", current_age: "43",
        birthday_input_basis: "year"
      )

      assert birthday.valid?
      assert_equal Date.new(1983, 9, 3), birthday.entry_date
      assert_equal 42, birthday.age
    end
  end

  test "birthday uses the selected age basis when the submitted year is stale" do
    travel_to Date.new(2026, 8, 25) do
      birthday = Entry::Birthday.new(
        friend: friends(:bob), entry_month: "9", entry_day: "3", entry_year: "1983", current_age: "43",
        birthday_input_basis: "age"
      )

      assert birthday.valid?
      assert_equal Date.new(1982, 9, 3), birthday.entry_date
      assert_equal 43, birthday.age
    end
  end

  test "birthday rejects an unsupported or empty input basis" do
    unsupported = Entry::Birthday.new(
      friend: friends(:bob), entry_month: "3", entry_day: "3", entry_year: "1983", birthday_input_basis: "date"
    )
    missing_age = Entry::Birthday.new(
      friend: friends(:bob), entry_month: "3", entry_day: "3", entry_year: "1983", birthday_input_basis: "age"
    )

    assert_not unsupported.valid?
    assert unsupported.errors.of_kind?(:entry_date, :invalid)
    assert_not missing_age.valid?
    assert missing_age.errors.of_kind?(:entry_date, :invalid)
  end

  test "birthday rejects a birth date in the future" do
    travel_to Date.new(2026, 8, 25) do
      birthday = Entry::Birthday.new(friend: friends(:bob), entry_month: "9", entry_day: "1", entry_year: "2026")

      assert_not birthday.valid?
      assert birthday.errors.of_kind?(:entry_date, :invalid)
    end
  end

  test "birthday rejects missing and impossible date parts" do
    missing_day = Entry::Birthday.new(friend: friends(:bob), entry_month: "3", entry_day: "")
    impossible_date = Entry::Birthday.new(friend: friends(:bob), entry_month: "2", entry_day: "30")

    assert_not missing_day.valid?
    assert missing_day.errors.of_kind?(:entry_date, :invalid)
    assert_not impossible_date.valid?
    assert impossible_date.errors.of_kind?(:entry_date, :invalid)
  end

  test "birthday can add or remove a known year" do
    birthday = Entry::Birthday.create!(friend: friends(:bob), entry_month: "3", entry_day: "3")

    birthday.update!(entry_month: "3", entry_day: "3", entry_year: "1983")
    assert_equal Date.new(1983, 3, 3), birthday.entry_date
    assert birthday.birthday_year_known?

    birthday.update!(entry_month: "3", entry_day: "3", entry_year: "")
    assert_equal Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, 3, 3), birthday.entry_date
    assert_not birthday.birthday_year_known?
  end

  test "non-birthday entries reject birthday year knowledge" do
    note = Entry::Note.new(friend: friends(:ada), content: { text: "Hello" }, birthday_year_known: true)

    assert_not note.valid?
    assert note.errors.of_kind?(:birthday_year_known, :present)
  end

  test "database requires birthdays to declare whether the year is known" do
    friend = users(:one).friends.create!(name: "Database Birthday")
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Entry.transaction(requires_new: true) do
        Entry.insert_all!([ {
          friend_id: friend.id,
          type: "Entry::Birthday",
          position: 0,
          entry_date: Date.new(1983, 3, 3),
          content: {},
          created_at: timestamp,
          updated_at: timestamp
        } ])
      end
    end
  end

  test "database keeps birthday year knowledge off other entry types" do
    timestamp = Time.current

    assert_raises ActiveRecord::StatementInvalid do
      Entry.transaction(requires_new: true) do
        Entry.insert_all!([ {
          friend_id: friends(:ada).id,
          type: "Entry::Note",
          position: 10,
          content: { text: "A note" },
          birthday_year_known: true,
          created_at: timestamp,
          updated_at: timestamp
        } ])
      end
    end
  end

  test "for_month defaults to current month" do
    travel_to Date.new(2026, 7, 1) do
      results = Entry::Birthday.for_month
      assert_includes results, entries(:grace_birthday)
      assert_not_includes results, entries(:ada_birthday)
    end
  end

  test "for_month with explicit month returns matching birthdays" do
    results = Entry::Birthday.for_month(Date.new(2026, 12, 1))

    assert_includes results, entries(:ada_birthday)
    assert_not_includes results, entries(:grace_birthday)
  end

  test "for_month returns empty for month with no birthdays" do
    results = Entry::Birthday.for_month(Date.new(2026, 1, 1))

    assert_empty results
  end

  test "friend.entries includes all types" do
    entries = friends(:ada).entries

    assert_equal 3, entries.size
    assert_includes entries.map(&:type), "Entry::Phone"
    assert_includes entries.map(&:type), "Entry::Birthday"
    assert_includes entries.map(&:type), "Entry::Email"
  end

  test "entry changes touch the friend" do
    friend = friends(:ada)
    original_updated_at = friend.reload.updated_at

    travel 1.minute
    entry = friend.entries.create!(type: "Entry::Note", content: { text: "old" })
    assert_operator friend.reload.updated_at, :>, original_updated_at
    created_at = friend.updated_at

    travel 1.minute
    entry.update!(content: { text: "updated" })
    assert_operator friend.reload.updated_at, :>, created_at
    updated_at = friend.updated_at

    travel 1.minute
    entry.destroy!
    assert_operator friend.reload.updated_at, :>, updated_at
  end
end
