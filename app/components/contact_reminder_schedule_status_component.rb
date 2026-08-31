class ContactReminderScheduleStatusComponent < ViewComponent::Base
  def initialize(first_reminder_on:)
    @first_reminder_on = first_reminder_on
  end

  private

  attr_reader :first_reminder_on
end
