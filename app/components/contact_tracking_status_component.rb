class ContactTrackingStatusComponent < ViewComponent::Base
  def initialize(latest_interaction:, reminder:, today:)
    @latest_interaction = latest_interaction
    @reminder = reminder
    @today = today
  end

  def render?
    latest_interaction.present? || reminder.enabled?
  end

  private

  attr_reader :latest_interaction, :reminder, :today

  def contact_logged?
    latest_interaction.present?
  end

  def contacted_today?
    latest_interaction.occurred_on == today
  end

  def time_since_contact
    helpers.distance_of_time_in_words(
      latest_interaction.occurred_on.in_time_zone,
      today.in_time_zone,
      except: [ :hours, :minutes, :seconds ]
    )
  end
end
