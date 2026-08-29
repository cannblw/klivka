class DueBirthdayReminderComponent < ViewComponent::Base
  with_collection_parameter :delivery

  def initialize(delivery:)
    @delivery = delivery
  end

  private

  attr_reader :delivery

  delegate :reminder_on, :occurrence_on, to: :delivery

  def birthday
    delivery.source
  end

  def person
    birthday.person
  end
end
