require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get settings_path

    assert_redirected_to new_session_url
  end

  test "show displays current preferences" do
    users(:one).update!(locale: "es", theme: "dark")

    get settings_path

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "h1", I18n.with_locale(:es) { I18n.t("settings.show.heading") }
    assert_select "main", /#{users(:one).email_address}/
    assert_select "input[type='radio'][value='es']", count: 1
    assert_select "input[type='radio'][value='dark']", count: 1
  end

  test "update persists the locale and re-renders in that language" do
    patch settings_path, params: { user: { locale: "es" } }

    assert_redirected_to settings_url
    assert_equal "es", users(:one).reload.locale
    follow_redirect!
    assert_select "html[lang=es]"
    assert_select "h1", "Ajustes"
  end

  test "update persists the theme" do
    patch settings_path, params: { user: { theme: "dark" } }

    assert_redirected_to settings_url
    assert_equal "dark", users(:one).reload.theme
    follow_redirect!
    assert_select "html[data-theme=dark]"
  end

  test "update persists both preferences at once" do
    patch settings_path, params: { user: { locale: "es", theme: "dark" } }

    users(:one).reload
    assert_equal "es", users(:one).locale
    assert_equal "dark", users(:one).theme
    assert_redirected_to settings_url
  end
end
