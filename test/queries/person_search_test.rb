require "test_helper"

class PersonSearchTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "returns all people alphabetically for a blank query" do
    assert_equal [ "Ada Lovelace", "Grace Hopper" ], PersonSearch.call(@user, "  ").map(&:name)
  end

  test "excludes archived people from blank and matching searches" do
    people(:ada).archive!

    assert_equal [ "Grace Hopper" ], PersonSearch.call(@user, nil).map(&:name)
    assert_empty PersonSearch.call(@user, "ada")
  end

  test "supports each sort and direction for matching queries" do
    alice = Person.create!(user: @user, name: "Alice Contact")
    maria = Person.create!(user: @user, name: "Maria Contact")
    zoe = Person.create!(user: @user, name: "Zoe Contact")
    now = Time.current

    alice.update_columns(created_at: now + 2.minutes, updated_at: now + 1.minute)
    maria.update_columns(created_at: now + 1.minute, updated_at: now + 3.minutes)
    zoe.update_columns(created_at: now + 3.minutes, updated_at: now + 2.minutes)

    sort_cases = {
      "name" => [ "Alice Contact", "Maria Contact", "Zoe Contact" ],
      "recently_added" => [ "Zoe Contact", "Alice Contact", "Maria Contact" ],
      "recently_updated" => [ "Maria Contact", "Zoe Contact", "Alice Contact" ]
    }

    sort_cases.each do |sort, expected_names|
      assert_equal expected_names, PersonSearch.call(@user, "contact", sort: sort).map(&:name), sort
    end
  end

  test "falls back to name sorting for an invalid sort" do
    assert_equal [ "Ada Lovelace", "Grace Hopper" ],
      PersonSearch.call(@user, nil, sort: "updated_at desc; drop table people").map(&:name)
  end

  test "only searches the given user's people" do
    Person.create!(user: users(:two), name: "Bob")

    assert_empty PersonSearch.call(@user, "Bob")
  end

  test "ranks exact names before prefix matches" do
    Person.create!(user: @user, name: "John")
    Person.create!(user: @user, name: "Johnny Appleseed")

    assert_equal [ "John", "Johnny Appleseed" ], PersonSearch.call(@user, "john").map(&:name)
  end

  test "ranks matches by relevance before name" do
    Person.create!(user: @user, name: "Adelina Walker I")
    Person.create!(user: @user, name: "Adolph Rempel")
    Person.create!(user: @user, name: "Amb. Robby Funk")
    Person.create!(user: @user, name: "Benjamin Nienow VM")
    Person.create!(user: @user, name: "Archie Huels")
    Person.create!(user: @user, name: "Carrol Cole")
    Person.create!(user: @user, name: "Carter Kirlin")

    assert_equal "Adolph Rempel", PersonSearch.call(@user, "adolp").first.name
    assert_equal "Benjamin Nienow VM", PersonSearch.call(@user, "jam").first.name
    assert_equal [ "Carrol Cole", "Carter Kirlin" ], PersonSearch.call(@user, "car").first(2).map(&:name)
  end

  test "uses the selected sort only to break relevance ties" do
    exact = Person.create!(user: @user, name: "Contact")
    prefix = Person.create!(user: @user, name: "Contact Person")
    now = Time.current

    exact.update_columns(created_at: now, updated_at: now)
    prefix.update_columns(created_at: now + 2.minutes, updated_at: now + 2.minutes)

    %w[recently_added recently_updated].each do |sort|
      assert_equal [ "Contact", "Contact Person" ], PersonSearch.call(@user, "contact", sort: sort).map(&:name), sort
    end
  end

  test "orders each match band ahead of weaker matches" do
    names = [
      "John",
      "Johnny Appleseed",
      "A Johnathan",
      "Longjohn Silver",
      "Jack Oscar Henry Nelson",
      "Joan"
    ]
    names.each { |name| Person.create!(user: @user, name: name) }

    results = PersonSearch.call(@user, "john").map(&:name)

    names.each_cons(2) { |stronger, weaker| assert_operator results.index(stronger), :<, results.index(weaker) }
  end

  test "matches prefixes on every name token" do
    Person.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], PersonSearch.call(@user, "smi").map(&:name)
  end

  test "matches substrings within names" do
    assert_equal [ "Ada Lovelace" ], PersonSearch.call(@user, "ovel").map(&:name)
  end

  test "matches initials" do
    Person.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], PersonSearch.call(@user, "js").map(&:name)
  end

  test "matches names without diacritics" do
    Person.create!(user: @user, name: "José Álvarez")

    assert_equal [ "José Álvarez" ], PersonSearch.call(@user, "jose").map(&:name)
  end

  test "matches misspellings" do
    Person.create!(user: @user, name: "Jonathan")

    assert_equal [ "Jonathan" ], PersonSearch.call(@user, "jonatahn").map(&:name)
  end

  test "matches reordered name tokens" do
    Person.create!(user: @user, name: "John Smith")

    assert_equal [ "John Smith" ], PersonSearch.call(@user, "smith john").map(&:name)
  end

  test "does not use fuzzy matching for one-character queries" do
    Person.create!(user: @user, name: "Zoe")

    assert_empty PersonSearch.call(@user, "q")
  end

  test "rejects weak fuzzy matches" do
    assert_empty PersonSearch.call(@user, "zzzz")
  end

  test "orders equal scores alphabetically" do
    Person.create!(user: @user, name: "Alicia")
    Person.create!(user: @user, name: "Alison")

    assert_equal [ "Alicia", "Alison" ], PersonSearch.call(@user, "ali").map(&:name)
  end

  test "limits non-empty searches to the configured maximum" do
    maximum_results = Rails.application.config.x.person_search_max_results
    (maximum_results + 1).times { |index| Person.create!(user: @user, name: "Alex #{index}") }

    assert_equal maximum_results, PersonSearch.call(@user, "alex").size
  end

  test "applies the result limit after relevance ranking" do
    maximum_results = Rails.application.config.x.person_search_max_results
    maximum_results.times { |index| Person.create!(user: @user, name: "A John #{index}") }
    Person.create!(user: @user, name: "John")

    results = PersonSearch.call(@user, "john")

    assert_equal maximum_results, results.size
    assert_equal "John", results.first.name
  end

  test "filters people by each birthday state" do
    unknown_year = Person.create!(user: @user, name: "Unknown Year")
    Entry::Birthday.create!(
      person: unknown_year,
      entry_date: Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, 4, 12),
      birthday_year_known: false
    )
    no_birthday = Person.create!(user: @user, name: "No Birthday")

    assert_equal [ no_birthday ], PersonSearch.call(@user, nil, filters: { birthday: "missing" })
    assert_equal [ unknown_year ], PersonSearch.call(@user, nil, filters: { birthday: "year_unknown" })
  end

  test "filters people by category and uncategorized state" do
    people(:ada).update!(category: categories(:family))

    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { category: categories(:family).id })
    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil, filters: { category: "uncategorized" })
  end

  test "does not accept another user's category filter" do
    people(:ada).update!(category: categories(:family))

    results = PersonSearch.call(@user, nil, filters: { category: categories(:family_for_user_two).id })

    assert_equal [ "Ada Lovelace", "Grace Hopper" ], results.map(&:name)
  end

  test "filters active, archived, and all people" do
    people(:ada).archive!

    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil)
    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { state: "archived" })
    assert_equal [ people(:ada), people(:grace) ].sort_by(&:name),
      PersonSearch.call(@user, nil, filters: { state: "all" })
  end

  test "filters people who have never been contacted" do
    people(:ada).interactions.create!(occurred_on: Date.new(2026, 8, 1))

    assert_equal [ people(:grace) ], PersonSearch.call(
      @user,
      nil,
      filters: { last_contact: "never" },
      on: Date.new(2026, 8, 28)
    )
  end

  test "uses inclusive nonoverlapping last-contact ranges" do
    on = Date.new(2026, 8, 28)
    contact_ages = {
      "Contact Today" => 0,
      "Contact 30 Days" => 30,
      "Contact 31 Days" => 31,
      "Contact 90 Days" => 90,
      "Contact 91 Days" => 91,
      "Contact 180 Days" => 180,
      "Contact 181 Days" => 181
    }
    people_by_age = contact_ages.to_h do |name, age|
      person = Person.create!(user: @user, name:)
      person.interactions.create!(occurred_on: on - age.days, validation_date: on)
      [ age, person ]
    end

    expected_ages = {
      "within_30_days" => [ 0, 30 ],
      "31_to_90_days" => [ 31, 90 ],
      "91_to_180_days" => [ 91, 180 ],
      "over_180_days" => [ 181 ]
    }

    expected_ages.each do |filter, ages|
      results = PersonSearch.call(@user, nil, filters: { last_contact: filter }, on:)
      assert_equal ages.map { people_by_age.fetch(_1) }.sort_by(&:name), results, filter
    end
  end

  test "last-contact filters use only the latest interaction" do
    on = Date.new(2026, 8, 28)
    person = Person.create!(user: @user, name: "Two Contacts")
    person.interactions.create!(occurred_on: on - 100.days, validation_date: on)
    person.interactions.create!(occurred_on: on - 10.days, validation_date: on)

    assert_includes PersonSearch.call(@user, nil, filters: { last_contact: "within_30_days" }, on:), person
    assert_not_includes PersonSearch.call(@user, nil, filters: { last_contact: "91_to_180_days" }, on:), person
  end

  test "composes filters with search and sorting" do
    match = Person.create!(user: @user, name: "Alex Match", category: categories(:family))
    other_category = Person.create!(user: @user, name: "Alex Other", category: categories(:friends))
    wrong_name = Person.create!(user: @user, name: "Taylor Match", category: categories(:family))
    [ match, other_category, wrong_name ].each do |person|
      person.interactions.create!(occurred_on: Date.new(2026, 8, 1))
    end

    results = PersonSearch.call(
      @user,
      "alex",
      sort: "recently_updated",
      filters: { category: categories(:family).id, last_contact: "within_30_days" },
      on: Date.new(2026, 8, 28)
    )

    assert_equal [ match ], results
  end

  test "requires every selected block-presence rule to match" do
    gift_list = Entry::GiftList.create!(
      person: people(:grace),
      title: "Christmas",
      items: [ { "text" => "Book" } ]
    )

    results = PersonSearch.call(
      @user,
      nil,
      filters: { has_blocks: %w[phone birthday], missing_blocks: %w[note gift_list] }
    )

    assert_equal [ people(:ada) ], results
    assert_equal "Christmas", gift_list.title
  end

  test "a contradictory block-presence filter returns no people" do
    results = PersonSearch.call(
      @user,
      nil,
      filters: { has_blocks: [ "email" ], missing_blocks: [ "email" ] }
    )

    assert_empty results
  end

  test "block filters match exact entry types" do
    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { has_blocks: [ "email" ] })
    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil, filters: { missing_blocks: [ "email" ] })
    assert_equal [ people(:ada), people(:grace) ],
      PersonSearch.call(@user, nil, filters: { missing_blocks: [ "date" ] })
  end

  test "filters effective contact reminders while the global policy is off" do
    ContactReminder.for(people(:ada)).override!(cadence: "monthly", on: @user.local_date)

    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { contact_reminder: "on" })
    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil, filters: { contact_reminder: "off" })
  end

  test "filters inherited reminders and individual opt-outs while the global policy is on" do
    @user.update!(contact_reminders_enabled_on: @user.local_date)
    ContactReminder.for(people(:grace)).opt_out!

    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { contact_reminder: "on" })
    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil, filters: { contact_reminder: "off" })
  end

  test "filters meaningful dates with and without reminders" do
    reminded_date = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 12, 1), label: "Anniversary")
    reminded_date.create_entry_reminder!
    Entry::Date.create!(person: people(:grace), entry_date: Date.new(2026, 11, 1), label: "Event")

    assert_equal [ people(:ada) ], PersonSearch.call(@user, nil, filters: { date_reminder: "present" })
    assert_equal [ people(:grace) ], PersonSearch.call(@user, nil, filters: { date_reminder: "missing" })
  end

  test "a person can have both reminded and unreminded meaningful dates" do
    reminded_date = Entry::Date.create!(person: people(:ada), entry_date: Date.new(2026, 12, 1), label: "Anniversary")
    reminded_date.create_entry_reminder!
    Entry::Date.create!(person: people(:ada), entry_date: Date.new(2027, 1, 1), label: "Renewal")

    assert_includes PersonSearch.call(@user, nil, filters: { date_reminder: "present" }), people(:ada)
    assert_includes PersonSearch.call(@user, nil, filters: { date_reminder: "missing" }), people(:ada)
  end

  test "people without meaningful dates match neither date-reminder filter" do
    person = Person.create!(user: @user, name: "No Dates")

    assert_not_includes PersonSearch.call(@user, nil, filters: { date_reminder: "present" }), person
    assert_not_includes PersonSearch.call(@user, nil, filters: { date_reminder: "missing" }), person
  end

  test "normalizes invalid filters and exposes canonical URL parameters" do
    search = PersonSearch.new(
      @user,
      "  ada  ",
      sort: "created_at desc",
      filters: { birthday: "partial", last_contact: "overdue", category: "1 OR 1=1", state: "deleted" }
    )

    assert_equal(
      {
        birthday: nil,
        last_contact: nil,
        category: nil,
        state: "active",
        has_blocks: [],
        missing_blocks: [],
        contact_reminder: nil,
        date_reminder: nil
      },
      search.filters
    )
    assert_equal({ query: "ada" }, search.url_params)
    assert_not search.filtered?
    assert_equal [ people(:ada) ], search.call
  end

  test "exposes nondefault filters as canonical URL parameters" do
    search = PersonSearch.new(
      @user,
      nil,
      sort: "recently_added",
      filters: {
        birthday: "missing",
        last_contact: "never",
        category: categories(:family).id,
        state: "all",
        has_blocks: %w[gift_list email email unknown],
        missing_blocks: "note",
        contact_reminder: "on",
        date_reminder: "missing"
      }
    )

    assert_equal(
      {
        sort: "recently_added",
        birthday: "missing",
        last_contact: "never",
        category: categories(:family).id.to_s,
        state: "all",
        has_blocks: %w[email gift_list],
        missing_blocks: [ "note" ],
        contact_reminder: "on",
        date_reminder: "missing"
      },
      search.url_params
    )
    assert search.filtered?
  end

  test "filters remain tenant isolated when archived people are included" do
    people(:bob).archive!

    results = PersonSearch.call(@user, nil, filters: { state: "all" })

    assert_not_includes results, people(:bob)
  end
end
