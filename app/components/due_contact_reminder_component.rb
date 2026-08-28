class DueContactReminderComponent < ViewComponent::Base
  with_collection_parameter :due_reminder

  def initialize(due_reminder:, time_zone: due_reminder.person.user.time_zone, interactions_by_person_id: {}, open_person_id: nil)
    @due_reminder = due_reminder
    @time_zone = time_zone
    @interactions_by_person_id = interactions_by_person_id
    @open_person_id = open_person_id
  end

  private

  attr_reader :due_reminder, :time_zone

  delegate :person, :reminder_on, to: :due_reminder

  def interaction
    @interactions_by_person_id[person.id] || person.interactions.new(occurred_on: Date.current)
  end

  def open?
    @open_person_id == person.id
  end

  def dialog_id
    "#{QuickInteractionComponent::DOM_ID}-#{person.id}"
  end
end
