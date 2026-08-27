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
end
