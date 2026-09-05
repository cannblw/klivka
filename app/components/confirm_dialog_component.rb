class ConfirmDialogComponent < ViewComponent::Base
  DOM_ID = "confirmation-dialog"

  def self.trigger_data(url:, title:, body:, confirm_label:, cancel_label:, turbo_method: nil, destructive: true,
    focus_id: nil, confirmation_event: nil)
    {
      controller: "confirm-dialog-trigger",
      action: "click->confirm-dialog-trigger#open",
      confirm_dialog_url: url,
      confirm_dialog_title: title,
      confirm_dialog_body: body,
      confirm_dialog_confirm_label: confirm_label,
      confirm_dialog_cancel_label: cancel_label,
      confirm_dialog_turbo_method: turbo_method,
      confirm_dialog_destructive: destructive,
      confirm_dialog_focus_id: focus_id,
      confirm_dialog_confirmation_event: confirmation_event
    }.compact
  end

  private

  def variant_classes(variant)
    ButtonComponent::VARIANTS.fetch(variant)
  end

  def title_id
    "#{DOM_ID}-title"
  end

  def body_id
    "#{DOM_ID}-body"
  end
end
