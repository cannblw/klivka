require "test_helper"

class ConfirmDialogComponentTest < ViewComponent::TestCase
  test "renders one empty dialog configured by the shared controller" do
    render_inline ConfirmDialogComponent.new

    assert_selector "dialog##{ConfirmDialogComponent::DOM_ID}[data-controller='confirm-dialog']"
    assert_selector "dialog[data-action~='confirm-dialog:open@window->confirm-dialog#open']"
    assert_selector "dialog[aria-labelledby='confirmation-dialog-title'][aria-describedby='confirmation-dialog-body']"
    assert_selector "h2#confirmation-dialog-title[data-confirm-dialog-target='title']", text: ""
    assert_selector "p#confirmation-dialog-body[data-confirm-dialog-target='body']", text: ""
    assert_selector "button[data-confirm-dialog-target='cancel'][data-action='confirm-dialog#close']"
    assert_selector "form[data-confirm-dialog-target='form']"
    assert_selector "form[data-action='turbo:submit-end->confirm-dialog#closeAfterSubmit']"
    assert_selector "input[name='_method'][data-confirm-dialog-target='method'][disabled]", visible: :all
    assert_selector "button[type='submit'][data-confirm-dialog-target='confirm'][data-action='confirm-dialog#confirm']"
  end

  test "builds destructive trigger data with a Turbo method" do
    data = ConfirmDialogComponent.trigger_data(
      url: "/people/ada",
      title: "Delete this?",
      body: "This cannot be undone.",
      confirm_label: "Delete",
      cancel_label: "Cancel",
      turbo_method: :delete
    )

    assert_equal "confirm-dialog-trigger", data.fetch(:controller)
    assert_equal "click->confirm-dialog-trigger#open", data.fetch(:action)
    assert_equal "/people/ada", data.fetch(:confirm_dialog_url)
    assert_equal "Delete this?", data.fetch(:confirm_dialog_title)
    assert_equal "This cannot be undone.", data.fetch(:confirm_dialog_body)
    assert_equal "Delete", data.fetch(:confirm_dialog_confirm_label)
    assert_equal "Cancel", data.fetch(:confirm_dialog_cancel_label)
    assert_equal :delete, data.fetch(:confirm_dialog_turbo_method)
    assert_equal true, data.fetch(:confirm_dialog_destructive)
  end

  test "builds non-destructive trigger data without an empty Turbo method" do
    data = ConfirmDialogComponent.trigger_data(
      url: "/people/ada/archive",
      title: "Archive this?",
      body: "You can restore this later.",
      confirm_label: "Archive",
      cancel_label: "Cancel",
      destructive: false,
      confirmation_event: "example:confirmed"
    )

    assert_equal false, data.fetch(:confirm_dialog_destructive)
    assert_equal "example:confirmed", data.fetch(:confirm_dialog_confirmation_event)
    assert_not data.key?(:confirm_dialog_turbo_method)
  end
end
