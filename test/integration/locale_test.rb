require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "renders in Spanish when the browser prefers it" do
    get root_url, headers: { "Accept-Language" => "es-ES,es;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "h1", "Amigos"
  end

  test "falls back to English for unsupported locales" do
    get root_url, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    assert_response :success
    assert_select "html[lang=en]"
    assert_select "h1", "Friends"
  end

  test "defaults to English without an Accept-Language header" do
    get root_url

    assert_response :success
    assert_select "h1", "Friends"
  end
end
