require "test_helper"

class BirthdaysControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get birthdays_url

    assert_redirected_to new_session_url
  end

  test "shows the current and future months while keeping earlier months collapsed" do
    travel_to Date.new(2026, 8, 1) do
      get birthdays_url

      assert_response :success
      assert_select "[data-birthdays-agenda='upcoming']", /Ada Lovelace/
      assert_select "details[data-birthdays-agenda='past']:not([open])", /Grace Hopper/
    end
  end

  test "shows one arbitrary month from the month picker" do
    travel_to Date.new(2026, 8, 1) do
      get birthdays_url(month: 7)

      assert_response :success
      assert_select "nav a[aria-current='page'][href='#{birthdays_path(month: 7)}']"
      assert_select "main", /Grace Hopper/
      assert_select "main", text: /Ada Lovelace/, count: 0
      assert_select "[data-birthdays-agenda]", count: 0
    end
  end

  test "shows a focused empty state for a month without birthdays" do
    travel_to Date.new(2026, 8, 1) do
      get birthdays_url(month: 1)

      assert_response :success
      assert_select "[data-birthdays-empty='month']"
      assert_select "[data-birthdays-empty='upcoming']", count: 0
    end
  end

  test "invalid months fall back to the current and upcoming agenda" do
    travel_to Date.new(2026, 8, 1) do
      get birthdays_url(month: "thirteen")

      assert_response :success
      assert_select "nav a[aria-current='page'][href='#{birthdays_path}']"
      assert_select "[data-birthdays-agenda='upcoming']"
    end
  end

  test "the birthday agenda uses the user's current month" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles")
    sign_out
    sign_in_as user

    travel_to Time.utc(2026, 8, 1, 0, 30) do
      get birthdays_url

      assert_response :success
      assert_select "[data-birthdays-agenda='upcoming']", /Grace Hopper/
      assert_select "details[data-birthdays-agenda='past']", count: 0
    end
  end

  test "only shows birthdays belonging to the current user" do
    sign_in_as users(:two)
    get birthdays_url

    assert_response :success
    assert_select "main", text: /Ada Lovelace/, count: 0
    assert_select "main", text: /Grace Hopper/, count: 0
    assert_select "[data-birthdays-empty='upcoming']"
  end

  test "does not show birthdays belonging to archived people" do
    people(:ada).archive!

    get birthdays_url(month: 12)

    assert_response :success
    assert_select "main", text: /Ada Lovelace/, count: 0
  end

  test "birthday cards link to person profiles and show the age reached that year" do
    travel_to Date.new(2026, 12, 31) do
      get birthdays_url(month: 12)

      profile_path = Rails.application.routes.url_helpers.person_path(
        people(:ada),
        { from: "birthdays", month: 12 }
      )
      profile_link = css_select("a").find { _1["href"] == profile_path }
      assert_not_nil profile_link
      assert_match(/Ada Lovelace/, profile_link.text)
      assert_select "main", /211 years old/
      assert_select "main", /December 10, 2026/
      assert_select "main", text: /1815/, count: 0
    end
  end

  test "orders birthdays within a month by day and then person name" do
    first_person = users(:one).people.create!(name: "Zelda Early")
    second_person = users(:one).people.create!(name: "Aaron Same Day")
    third_person = users(:one).people.create!(name: "Zelda Same Day")
    Entry::Birthday.create!(person: first_person, entry_date: Date.new(1990, 12, 1))
    Entry::Birthday.create!(person: second_person, entry_date: Date.new(1990, 12, 5))
    Entry::Birthday.create!(person: third_person, entry_date: Date.new(1990, 12, 5))

    get birthdays_url(month: 12)

    names = response.body.scan(/(Zelda Early|Aaron Same Day|Zelda Same Day)/).flatten
    assert_equal [ "Zelda Early", "Aaron Same Day", "Zelda Same Day" ], names
  end

  test "birthday agenda shows an occurrence without inventing an age for an unknown year" do
    person = users(:one).people.create!(name: "Yearless Birthday")
    Entry::Birthday.create!(
      person:, entry_date: Date.new(Entry::Birthday::UNKNOWN_YEAR_ANCHOR, 3, 3), birthday_year_known: false
    )

    travel_to Date.new(2026, 3, 1) do
      get birthdays_url(month: 3)

      occurrence = I18n.l(Date.new(2026, 3, 3), format: :long)
      assert_select "main", /#{Regexp.escape(occurrence)}/
      assert_select "main", text: /years old/, count: 0
      assert_select "main", text: /2000/, count: 0
    end
  end

  test "shows the global birthday reminder status" do
    get birthdays_url

    assert_select "[data-birthday-reminder-status='enabled']"
    assert_select "[data-birthday-reminder-status] a[href='#{settings_path}']"
  end
end
