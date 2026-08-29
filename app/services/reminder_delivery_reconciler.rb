class ReminderDeliveryReconciler
  def self.current?(delivery, at: Time.current)
    new(user: delivery.user, at:).current_delivery?(delivery)
  end

  def self.current(deliveries:, user:, at: Time.current)
    new(user:, at:).current_deliveries(deliveries)
  end

  def self.call(user:, at: Time.current, channel: nil)
    new(user:, at:, channel:).call
  end

  def initialize(user:, at:, channel: nil)
    @user = user
    @at = at
    @channel = channel
  end

  def call
    canceled_count = 0

    unclaimed_pending_deliveries.in_batches(of: batch_size) do |batch|
      deliveries = batch.preload(:source).to_a
      sources = deliveries.filter_map(&:source)
      preload_entries(sources)
      preload_people(sources)
      latest_interactions = latest_interactions_for(sources)
      canceled_ids = deliveries.filter_map do |delivery|
        delivery.id unless current?(delivery, latest_interactions:)
      end
      next if canceled_ids.empty?

      canceled_count += unclaimed_pending_deliveries.where(id: canceled_ids).update_all(
        status: ReminderDelivery::CANCELED_STATUS,
        canceled_at: at,
        claimed_at: nil,
        claim_token: nil,
        updated_at: at
      )
    end

    Rails.logger.info("Canceled stale reminder delivery work count=#{canceled_count}") if canceled_count.positive?
    canceled_count
  end

  def current_delivery?(delivery)
    current_deliveries([ delivery ]).any?
  end

  def current_deliveries(deliveries)
    sources = deliveries.filter_map(&:source)
    preload_entries(sources)
    preload_people(sources)
    latest_interactions = latest_interactions_for(sources)
    deliveries.select { |delivery| delivery.source && current?(delivery, latest_interactions:) }
  end

  private

  attr_reader :user, :at, :channel

  def unclaimed_pending_deliveries
    deliveries = user.reminder_deliveries.where(status: ReminderDelivery::PENDING_STATUS, claimed_at: nil)
    channel ? deliveries.where(channel:) : deliveries
  end

  def current?(delivery, latest_interactions:)
    channel_enabled?(delivery.channel) && source_current?(delivery, latest_interactions:)
  end

  def channel_enabled?(channel)
    user.reminder_channel_enabled?(channel)
  end

  def source_current?(delivery, latest_interactions:)
    source = delivery.source
    return false if source_person(source)&.archived?

    case source
    when Person
      keep_in_touch_current?(source, delivery, latest_interaction_on: latest_interactions[source.id])
    when EntryReminder
      entry_reminder_current?(source, delivery)
    when Entry::Birthday
      birthday_reminder_current?(source, delivery)
    else
      false
    end
  end

  def keep_in_touch_current?(person, delivery, latest_interaction_on:)
    local_date = user.local_date(at:)
    reminder = ContactReminder.for(person, user:)
    reminder.enabled? && reminder.due?(on: local_date, latest_interaction_on:) &&
      reminder.next_suggestion_on(latest_interaction_on:) == delivery.reminder_on &&
      delivery.occurrence_on == delivery.reminder_on
  end

  def entry_reminder_current?(reminder, delivery)
    reminder.next_reminder_on(on: delivery.reminder_on) == delivery.reminder_on &&
      delivery.occurrence_on == delivery.reminder_on + reminder.lead_days
  end

  def birthday_reminder_current?(birthday, delivery)
    return false unless user.birthday_reminders_enabled?

    occurrence_on = birthday.occurrence_on(year: delivery.occurrence_on.year)
    delivery.occurrence_on == occurrence_on &&
      delivery.reminder_on == occurrence_on - user.birthday_reminder_lead_days
  end

  def preload_entries(sources)
    reminders = sources.grep(EntryReminder)
    return if reminders.empty?

    ActiveRecord::Associations::Preloader.new(records: reminders, associations: { entry: :person }).call
  end

  def preload_people(sources)
    people = sources.grep(Person)
    ActiveRecord::Associations::Preloader.new(records: people, associations: :keep_in_touch_setting).call if people.any?

    sources_with_people = sources.grep(Entry::Birthday)
    return if sources_with_people.empty?

    ActiveRecord::Associations::Preloader.new(records: sources_with_people, associations: :person).call
  end

  def source_person(source)
    case source
    when Person then source
    when Entry::Birthday then source.person
    when EntryReminder then source.entry.person
    end
  end

  def latest_interactions_for(sources)
    person_ids = sources.grep(Person).map(&:id)
    return {} if person_ids.empty?

    Interaction.where(person_id: person_ids).group(:person_id).maximum(:occurred_on)
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end
end
