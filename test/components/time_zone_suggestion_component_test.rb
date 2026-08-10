require "test_helper"

class TimeZoneSuggestionComponentTest < ViewComponent::TestCase
  test "renders a hidden update suggestion for the user's timezone" do
    user = users(:one)
    user.update!(time_zone: "Europe/Madrid")

    render_inline TimeZoneSuggestionComponent.new(user: user)

    assert_selector "#time-zone-suggestion[hidden][data-controller='time-zone-suggestion']", visible: :all
    assert_selector "#time-zone-suggestion[data-time-zone-suggestion-profile-time-zone-value='Europe/Madrid']", visible: :all
    assert_selector "form[action='#{Rails.application.routes.url_helpers.time_zone_path}'] input[name='time_zone']", visible: :all
    assert_selector "button", text: "Update time zone", visible: :all
    assert_selector "button", text: "Keep current time zone", visible: :all
  end
end
