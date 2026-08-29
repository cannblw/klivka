class DueContactReminderComponent < ViewComponent::Base
  with_collection_parameter :delivery

  def initialize(delivery:, time_zone: delivery.user.time_zone, interactions_by_person_id: {}, open_person_id: nil)
    @delivery = delivery
    @time_zone = time_zone
    @interactions_by_person_id = interactions_by_person_id
    @open_person_id = open_person_id
  end

  private

  attr_reader :delivery, :time_zone

  delegate :reminder_on, to: :delivery

  def person
    delivery.source
  end

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
