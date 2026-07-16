class FlashComponent < ViewComponent::Base
  KINDS = {
    notice: { background: "bg-emerald-600", role: "status" },
    alert: { background: "bg-red-500", role: "alert" }
  }.freeze

  def initialize(kind:, message:)
    @kind = kind.to_sym
    @message = message
  end

  private

  attr_reader :message

  def background_class
    KINDS.fetch(@kind).fetch(:background)
  end

  def role
    KINDS.fetch(@kind).fetch(:role)
  end
end
