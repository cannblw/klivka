require "test_helper"

class AccountImportPreviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    Rails.cache.clear
  end

  teardown { Rails.cache.clear }

  test "account import preview requires authentication" do
    sign_out

    post account_import_preview_path, params: { account_import: { file: export_file } }

    assert_redirected_to new_session_url
  end

  test "account import preview validates an export without retaining its contents" do
    original_counts = account_record_counts

    post account_import_preview_path, params: { account_import: { file: export_file } }, as: :multipart_form

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal({
      "valid" => true,
      "summary" => AccountImport::Document.parse(export_json).summary
    }, response.parsed_body)
    assert_equal original_counts, account_record_counts
    assert_not_includes response.body, users(:one).email_address
    assert_not_includes response.body, people(:ada).name
  end

  test "account import preview rejects a missing file" do
    post account_import_preview_path, params: { account_import: {} }

    assert_response :unprocessable_entity
    assert_not response.parsed_body["valid"]
  end

  test "account import preview rejects a file larger than the configured limit before reading it" do
    upload = Object.new
    upload.define_singleton_method(:size) { Rails.application.config.x.account_import_max_file_size_bytes + 1 }
    upload.define_singleton_method(:read) { raise "oversized file should not be read" }

    post account_import_preview_path, params: { account_import: { file: upload } }

    assert_response :unprocessable_entity
    assert_not response.parsed_body["valid"]
  end

  test "account import preview rejects malformed and unsupported exports" do
    invalid_file = Rack::Test::UploadedFile.new(StringIO.new("not JSON"), "application/json", original_filename: "invalid.json")

    post account_import_preview_path, params: { account_import: { file: invalid_file } }

    assert_response :unprocessable_entity
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_not response.parsed_body["valid"]
    assert_equal "invalid_json", response.parsed_body["code"]
  end

  test "account import preview identifies an unsupported export version" do
    payload = JSON.parse(export_json)
    payload["format_version"] = 2
    unsupported_file = Rack::Test::UploadedFile.new(
      StringIO.new(JSON.generate(payload)),
      "application/json",
      original_filename: "unsupported.json"
    )

    post account_import_preview_path, params: { account_import: { file: unsupported_file } }

    assert_response :unprocessable_entity
    assert_equal "unsupported_version", response.parsed_body["code"]
  end

  test "account import preview limits repeated uploads per account" do
    Rails.application.config.x.account_import_upload_rate_limit.times do
      post account_import_preview_path, params: { account_import: { file: export_file } }
      assert_response :success
    end

    post account_import_preview_path, params: { account_import: { file: export_file } }

    assert_response :too_many_requests
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_not response.parsed_body["valid"]
  end

  private

  def export_file
    Rack::Test::UploadedFile.new(StringIO.new(export_json), "application/json", original_filename: "klivka-export.json")
  end

  def export_json
    JSON.generate(AccountExportSerializer.new(user: users(:one), generated_at: Time.utc(2026, 9, 2, 12)).as_json)
  end

  def account_record_counts
    {
      categories: Category.count,
      contact_methods: ContactMethod.count,
      people: Person.count,
      entries: Entry.count,
      interactions: Interaction.count
    }
  end
end
