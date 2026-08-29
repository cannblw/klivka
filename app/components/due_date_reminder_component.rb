class DueDateReminderComponent < ViewComponent::Base
  with_collection_parameter :delivery

  def initialize(delivery:)
    @delivery = delivery
  end

  private

  attr_reader :delivery

  delegate :reminder_on, :occurrence_on, to: :delivery

  def reminder
    delivery.source
  end

  def entry
    reminder.entry
  end

  def person
    entry.person
  end

  def label
    entry.label.presence || t("reminders.date.default_label")
  end

  def person_path
    helpers.person_path(person, from: "reminders", anchor: helpers.dom_id(entry))
  end
end
