class ReminderBellComponent < ViewComponent::Base
  def initialize(actionable:)
    @actionable = actionable
  end

  private

  def actionable?
    @actionable
  end

  def label
    t("reminder_bell.#{actionable? ? :actionable : :quiet}")
  end

  def icon
    actionable? ? "notifications" : "notifications_none"
  end
end
