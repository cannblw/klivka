require "test_helper"

class BirthdaysControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get birthdays_url

    assert_redirected_to new_session_url
  end

  test "lists birthdays for the current month" do
    travel_to Date.new(2026, 12, 1) do
      get birthdays_url

      assert_response :success
      assert_select "main", /Ada Lovelace/
      assert_select "main", text: /Grace Hopper/, count: 0
    end
  end

  test "shows empty state when no birthdays this month" do
    travel_to Date.new(2026, 1, 1) do
      get birthdays_url

      assert_response :success
      assert_select "main", /No birthdays this month/
    end
  end

  test "the birthday list uses the user's current month" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles")
    sign_out
    sign_in_as user

    travel_to Time.utc(2026, 8, 1, 0, 30) do
      get birthdays_url

      assert_response :success
      assert_select "main", /Grace Hopper/
    end
  end

  test "only shows birthdays for the current user" do
    sign_in_as users(:two)
    get birthdays_url

    assert_response :success
    assert_select "main", text: /Ada Lovelace/, count: 0
    assert_select "main", text: /Grace Hopper/, count: 0
  end

  test "displays age on birthday cards" do
    travel_to Date.new(2026, 12, 31) do
      get birthdays_url

      assert_select "main", /211 years old/
    end
  end
end
