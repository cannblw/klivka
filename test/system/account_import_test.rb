require "application_system_test_case"

class AccountImportTest < ApplicationSystemTestCase
  test "reviews and restores a Klivka export" do
    destination = users(:two)
    export_file = Tempfile.new([ "klivka-export", ".json" ])
    export_file.write(JSON.generate(AccountExportSerializer.new(user: users(:one)).as_json))
    export_file.close

    sign_in_as destination
    visit settings_path

    attach_file "Klivka export file", export_file.path, make_visible: true
    click_button "Review this import"

    assert_text "This export is ready to restore"
    click_button "Continue to confirmation"
    assert_selector "dialog#account-import-dialog[open]"
    fill_in "Current password", with: "wrong-password"
    click_button "Replace my data"

    assert_text "Enter your current password to restore this export."
    assert_text "This export is ready to restore"
    assert_text File.basename(export_file.path)

    fill_in "Current password", with: "password"
    click_button "Replace my data"

    assert_current_path settings_path
    assert_text "Your Klivka data has been restored."
    assert_equal users(:one).people.order(:id).pluck(:name), destination.people.order(:id).pluck(:name)
  ensure
    export_file&.unlink
  end
end
