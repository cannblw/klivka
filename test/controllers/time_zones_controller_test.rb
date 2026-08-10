require "test_helper"

class TimeZonesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "updates the user's timezone" do
    patch time_zone_path, params: { time_zone: "Asia/Kolkata" }

    assert_redirected_to root_url
    assert_equal "Asia/Kolkata", users(:one).reload.time_zone
    assert_equal "Time zone updated.", flash[:notice]
  end

  test "does not update the user with an unknown timezone" do
    original_time_zone = users(:one).time_zone

    patch time_zone_path, params: { time_zone: "Mars/Olympus_Mons" }

    assert_redirected_to settings_url
    assert_equal original_time_zone, users(:one).reload.time_zone
    assert_equal "Time zone could not be updated: Time zone is invalid", flash[:alert]
  end

  test "redirects unauthenticated timezone updates to sign in" do
    sign_out

    patch time_zone_path, params: { time_zone: "Asia/Kolkata" }

    assert_redirected_to new_session_url
  end
end
