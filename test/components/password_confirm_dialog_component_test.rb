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

  test "reopens with an inline password error after a failed submission" do
    render_inline PasswordConfirmDialogComponent.new(
      id: "deletion-dialog",
      title: "Delete your account?",
      body: "This cannot be undone.",
      form_id: "deletion-form",
      password_name: "account[password]",
      password_label: "Current password",
      password_hint: "Confirm your password.",
      confirm_label: "Delete",
      cancel_label: "Cancel",
      error: "Enter your current password.",
      open: true
    )

    assert_selector "dialog[data-dialog-open-value='true']"
    assert_selector "p#deletion-dialog-error[role='alert']:not([hidden])", text: "Enter your current password."
  end
end
