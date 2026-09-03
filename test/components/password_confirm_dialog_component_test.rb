require "test_helper"

class PasswordConfirmDialogComponentTest < ViewComponent::TestCase
  test "renders a destructive form confirmation with a required current password" do
    render_inline PasswordConfirmDialogComponent.new(
      id: "restore-dialog",
      title: "Replace your data?",
      body: "This cannot be undone.",
      form_id: "restore-form",
      password_name: "account_import[password]",
      password_label: "Current password",
      password_hint: "Confirm your password.",
      confirm_label: "Replace",
      cancel_label: "Cancel"
    )

    assert_selector "dialog#restore-dialog[aria-labelledby='restore-dialog-title'][aria-describedby='restore-dialog-body']"
    assert_selector "input[type='password'][name='account_import[password]'][form='restore-form'][required]"
    assert_selector "p#restore-dialog-error[role='alert'][hidden]", visible: false
    assert_selector "button[type='submit'][form='restore-form'].bg-red-600", text: "Replace"
    assert_selector "button[type='button']", text: "Cancel"
  end
end
