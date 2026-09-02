require "test_helper"

class AccountExportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "account export requires authentication" do
    sign_out

    get account_export_path

    assert_redirected_to new_session_url
  end

  test "downloads the current account data as uncached versioned JSON" do
    travel_to Time.utc(2026, 9, 2, 12, 34, 56) do
      get account_export_path
    end

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "attachment; filename=\"klivka-export-20260902T123456Z.json\"; filename*=UTF-8''klivka-export-20260902T123456Z.json",
      response.headers["Content-Disposition"]

    export = JSON.parse(response.body)
    assert_equal 1, export["format_version"]
    assert_equal "2026-09-02T12:34:56.000000Z", export["generated_at"]
    assert_equal users(:one).email_address, export.dig("account", "email_address")
    assert_equal users(:one).people.order(:id).pluck(:id), export["people"].pluck("id")
    assert_not_includes export["people"].pluck("id"), people(:bob).id
  end

  test "uses the authenticated account even when another account identifier is supplied" do
    get account_export_path, params: { user_id: users(:two).id }

    export = JSON.parse(response.body)
    assert_equal users(:one).email_address, export.dig("account", "email_address")
    assert_not_equal users(:two).email_address, export.dig("account", "email_address")
  end
end
