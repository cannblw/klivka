require "test_helper"

class AccountImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @destination = users(:two)
    sign_in_as @destination
    Rails.cache.clear
  end

  teardown { Rails.cache.clear }

  test "account import requires authentication" do
    sign_out

    post account_import_path, params: import_params

    assert_redirected_to new_session_url
  end

  test "account import replaces account data and schedules reminder reconciliation" do
    original_email = @destination.email_address

    assert_enqueued_with(job: ReminderScanJob, args: [ @destination.id ]) do
      post account_import_path, params: import_params
    end

    assert_redirected_to settings_url
    assert_equal original_email, @destination.reload.email_address
    assert_equal users(:one).people.order(:id).pluck(:name), @destination.people.order(:id).pluck(:name)
  end

  test "account import rejects the wrong password without changing account data" do
    before_import = serialized_account(@destination)

    assert_no_enqueued_jobs only: ReminderScanJob do
      post account_import_path, params: import_params(password: "wrong-password")
    end

    assert_redirected_to settings_url
    assert_equal before_import, serialized_account(@destination.reload)
  end

  test "account import reports the wrong password without navigating for a browser request" do
    post account_import_path,
      params: import_params(password: "wrong-password"),
      headers: { "Accept" => "application/json" }

    assert_response :unprocessable_entity
    assert_not response.parsed_body["success"]
    assert_equal "invalid_password", response.parsed_body["code"]
  end

  test "account import revalidates the submitted file before replacement" do
    before_import = serialized_account(@destination)
    invalid_file = Rack::Test::UploadedFile.new(StringIO.new("not JSON"), "application/json", original_filename: "invalid.json")

    post account_import_path, params: { account_import: { file: invalid_file, password: "password" } }

    assert_redirected_to settings_url
    assert_equal before_import, serialized_account(@destination.reload)
  end

  test "account import is unavailable in the shared demo" do
    with_demo_mode(user: @destination) do
      post account_import_path, params: import_params

      assert_redirected_to root_url
    end
  end

  private

  def import_params(password: "password")
    payload = AccountExportSerializer.new(user: users(:one), generated_at: Time.utc(2026, 9, 2, 12)).as_json
    file = Rack::Test::UploadedFile.new(
      StringIO.new(JSON.generate(payload)),
      "application/json",
      original_filename: "klivka-export.json"
    )
    { account_import: { file:, password: } }
  end

  def serialized_account(user)
    AccountExportSerializer.new(user:, generated_at: Time.utc(2026, 9, 2, 12)).as_json
  end
end
