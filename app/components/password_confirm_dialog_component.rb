class PasswordConfirmDialogComponent < ViewComponent::Base
  def initialize(id:, title:, body:, form_id:, password_name:, password_label:, password_hint:, confirm_label:, cancel_label:,
    error: nil, open: false)
    @id = id
    @title = title
    @body = body
    @form_id = form_id
    @password_name = password_name
    @password_label = password_label
    @password_hint = password_hint
    @confirm_label = confirm_label
    @cancel_label = cancel_label
    @error = error
    @open = open
  end

  private

  attr_reader :id, :title, :body, :form_id, :password_name, :password_label, :password_hint,
    :confirm_label, :cancel_label, :error, :open

  def title_id
    "#{id}-title"
  end

  def body_id
    "#{id}-body"
  end

  def password_id
    "#{id}-password"
  end

  def password_hint_id
    "#{id}-password-hint"
  end

  def error_id
    "#{id}-error"
  end
end
