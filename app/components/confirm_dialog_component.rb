class ConfirmDialogComponent < ViewComponent::Base
  def initialize(id:, title:, body:, confirm_label:, cancel_label:, confirm_link_id:, destructive: true, turbo_method: nil)
    @id = id
    @title = title
    @body = body
    @confirm_label = confirm_label
    @cancel_label = cancel_label
    @confirm_link_id = confirm_link_id
    @destructive = destructive
    @turbo_method = turbo_method
  end

  private

  attr_reader :id, :title, :body, :confirm_label, :cancel_label, :confirm_link_id, :turbo_method

  def destructive?
    @destructive
  end

  def confirm_classes
    base = "cursor-pointer rounded-lg px-4 py-2 text-sm font-medium text-white"
    color = destructive? ? "bg-red-600 hover:bg-red-500" : "bg-amber-600 hover:bg-amber-500"
    "#{base} #{color}"
  end

  def confirm_data
    data = { action: "click->dialog#close" }
    data[:turbo_method] = turbo_method if turbo_method
    data
  end

  def title_id
    "#{id}-title"
  end

  def body_id
    "#{id}-body"
  end
end
