require "test_helper"
require "yaml"

class LocaleTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "renders in Spanish when the browser prefers it" do
    get root_url, headers: { "Accept-Language" => "es-ES,es;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "html[lang=es]"
  end

  test "falls back to English for unsupported locales" do
    get root_url, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    assert_response :success
    assert_select "html[lang=en]"
  end

  test "defaults to English without an Accept-Language header" do
    get root_url

    assert_response :success
    assert_select "html[lang=en]"
  end

  test "user locale preference overrides Accept-Language header" do
    users(:one).update!(locale: "es")

    get root_url, headers: { "Accept-Language" => "en-US" }

    assert_response :success
    assert_select "html[lang=es]"
  end

  test "user locale falls back to header when no preference is set" do
    users(:one).update!(locale: nil)

    get root_url, headers: { "Accept-Language" => "es-ES" }

    assert_response :success
    assert_select "html[lang=es]"
  end

  test "data-theme is present on html when user has a theme set" do
    users(:one).update!(theme: "dark")

    get root_url

    assert_response :success
    assert_select "html[data-theme=dark]"
  end

  test "data-theme is blank when user has no theme set" do
    users(:one).update!(theme: nil)

    get root_url

    assert_response :success
    assert_select "html[data-theme='']"
  end

  test "layout renders discard changes dialog" do
    get root_url

    assert_select "dialog#discard-changes-dialog"
    assert_select "#discard-changes-confirm-link"
  end

  test "layout renders the hidden timezone suggestion" do
    get root_url

    assert_select "#time-zone-suggestion[hidden][data-controller='time-zone-suggestion']"
  end

  test "supported locales include every application translation" do
    english_translations = YAML.safe_load_file(Rails.root.join("config/locales/en.yml")).fetch("en")
    required_keys = translation_keys(english_translations)

    I18n.available_locales.each do |locale|
      missing_keys = required_keys.reject { |key| I18n.exists?(key, locale) }
      assert_empty missing_keys, "Missing #{locale} translations: #{missing_keys.join(", ")}"
    end
  end

  private

  def translation_keys(translations, prefix = nil)
    translations.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) ? translation_keys(value, path) : path
    end
  end
end
