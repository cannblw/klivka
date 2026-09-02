require "test_helper"

class ConfirmDialogComponentTest < ViewComponent::TestCase
  test "renders a dialog with the given id, title, and body" do
    render_inline ConfirmDialogComponent.new(
      id: "delete-dialog", title: "Delete this?", body: "This cannot be undone.",
      confirm_label: "Delete", cancel_label: "Cancel", confirm_link_id: "confirm-delete"
    )

    assert_selector "dialog#delete-dialog"
    assert_selector "h2", text: "Delete this?"
    assert_selector "p", text: "This cannot be undone."
  end

  test "uses the title and body to describe the dialog" do
    render_inline ConfirmDialogComponent.new(
      id: "delete-dialog", title: "Delete this?", body: "This cannot be undone.",
      confirm_label: "Delete", cancel_label: "Cancel", confirm_link_id: "confirm-delete"
    )

    assert_selector "dialog[aria-labelledby='delete-dialog-title'][aria-describedby='delete-dialog-body']"
    assert_selector "h2#delete-dialog-title"
    assert_selector "p#delete-dialog-body"
  end

  test "renders confirm and cancel actions" do
    render_inline ConfirmDialogComponent.new(
      id: "dialog", title: "Title", body: "Body",
      confirm_label: "Yes, delete", cancel_label: "Keep it", confirm_link_id: "confirm-link"
    )

    assert_selector "button", text: "Keep it"
    assert_selector "a#confirm-link", text: "Yes, delete"
  end

  test "applies destructive styling by default" do
    render_inline ConfirmDialogComponent.new(
      id: "dialog", title: "Title", body: "Body",
      confirm_label: "Delete", cancel_label: "Cancel", confirm_link_id: "confirm-link"
    )

    assert_selector "a.bg-red-600"
  end

  test "applies non-destructive styling when requested" do
    render_inline ConfirmDialogComponent.new(
      id: "dialog", title: "Title", body: "Body",
      confirm_label: "Confirm", cancel_label: "Cancel", confirm_link_id: "confirm-link",
      destructive: false
    )

    assert_selector "a.bg-amber-600"
    assert_no_selector "a.bg-red-600"
  end

  test "includes the Turbo method when specified" do
    render_inline ConfirmDialogComponent.new(
      id: "dialog", title: "Title", body: "Body",
      confirm_label: "Delete", cancel_label: "Cancel", confirm_link_id: "confirm-link",
      turbo_method: :delete
    )

    assert_selector "a[data-turbo-method='delete']"
  end

  test "omits the Turbo method when unspecified" do
    render_inline ConfirmDialogComponent.new(
      id: "dialog", title: "Title", body: "Body",
      confirm_label: "Delete", cancel_label: "Cancel", confirm_link_id: "confirm-link"
    )

    assert_no_selector "a[data-turbo-method]"
  end
end
