require "test_helper"

class SettingsPageComponentTest < ViewComponent::TestCase
  test "renders every destination and identifies the current page" do
    routes = Rails.application.routes.url_helpers

    render_inline(SettingsPageComponent.new(active: :reminders)) { "Reminder controls" }

    assert_selector "h1", text: "Reminders"
    assert_selector "nav[aria-label='Settings sections']"
    assert_selector "a[href='#{routes.settings_path}']", text: "Account"
    assert_selector "a[href='#{routes.settings_preferences_path}']", text: "Appearance and language"
    assert_selector "a[href='#{routes.settings_reminders_path}'][aria-current='page']", text: "Reminders"
    assert_equal "/settings/contact-methods", routes.contact_methods_path
    assert_selector "a[href='/settings/contact-methods']", text: "Contact methods"
    assert_text "Reminder controls"
  end

  test "rejects an unknown destination" do
    error = assert_raises(ArgumentError) do
      SettingsPageComponent.new(active: :unknown)
    end

    assert_equal "unknown settings destination: unknown", error.message
  end
end
