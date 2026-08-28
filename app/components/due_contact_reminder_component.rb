class DueContactReminderComponent < ViewComponent::Base
  with_collection_parameter :due_reminder

  def initialize(due_reminder:)
    @due_reminder = due_reminder
  end

  private

  attr_reader :due_reminder

  delegate :person, :reminder_on, to: :due_reminder
end
