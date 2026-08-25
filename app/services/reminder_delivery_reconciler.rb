class ReminderDeliveryReconciler
  def self.current?(delivery, at: Time.current)
    new(user: delivery.user, at:).current_delivery?(delivery)
  end

  def self.call(user:, at: Time.current)
    new(user:, at:).call
  end

  def initialize(user:, at:)
    @user = user
    @at = at
  end

  def call
    canceled_count = 0

    unclaimed_pending_deliveries.in_batches(of: batch_size) do |batch|
      deliveries = batch.preload(:source).to_a
      sources = deliveries.filter_map(&:source)
      preload_entries(sources)
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
    source = delivery.source
    return false unless source

    preload_entries([ source ])
    current?(delivery, latest_interactions: latest_interactions_for([ source ]))
  end

  private

  attr_reader :user, :at

  def unclaimed_pending_deliveries
    user.reminder_deliveries.where(status: ReminderDelivery::PENDING_STATUS, claimed_at: nil)
  end

  def current?(delivery, latest_interactions:)
    channel_enabled?(delivery.channel) && source_current?(delivery, latest_interactions:)
  end

  def channel_enabled?(channel)
    user.reminder_channel_enabled?(channel)
  end

  def source_current?(delivery, latest_interactions:)
    case (source = delivery.source)
    when KeepInTouchSetting
      keep_in_touch_current?(source, delivery, latest_interaction_on: latest_interactions[source.friend_id])
    when EntryReminder
      entry_reminder_current?(source, delivery)
    when Entry::Birthday
      birthday_reminder_current?(source, delivery)
    else
      false
    end
  end

  def keep_in_touch_current?(setting, delivery, latest_interaction_on:)
    local_date = user.local_date(at:)
    setting.enabled? && setting.due?(on: local_date, latest_interaction_on:) &&
      setting.next_suggestion_on(latest_interaction_on:) == delivery.reminder_on &&
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

    ActiveRecord::Associations::Preloader.new(records: reminders, associations: :entry).call
  end

  def latest_interactions_for(sources)
    friend_ids = sources.grep(KeepInTouchSetting).map(&:friend_id)
    return {} if friend_ids.empty?

    Interaction.where(friend_id: friend_ids).group(:friend_id).maximum(:occurred_on)
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end
end
