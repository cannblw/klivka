class ReminderDeliveryScheduler
  def self.call(user:, at: Time.current)
    new(user:, at:).call
  end

  def initialize(user:, at:)
    @user = user
    @at = at
  end

  def call
    local_date = user.local_date(at:)
    scan_dates = dates_to_scan(through: local_date)
    created_count = schedule_keep_in_touch_reminders(through: local_date)
    created_count += schedule_entry_reminders(during: scan_dates)
    created_count += schedule_birthday_reminders(during: scan_dates)
    user.update!(reminders_scanned_through_on: [ user.reminders_scanned_through_on, local_date ].compact.max)
    created_count
  end

  private

  attr_reader :user, :at

  def dates_to_scan(through:)
    checkpoint = user.reminders_scanned_through_on
    first_date = checkpoint && checkpoint < through ? checkpoint.next_day : through
    first_date..through
  end

  def schedule_keep_in_touch_reminders(through:)
    keep_in_touch_settings.in_batches(of: batch_size).sum do |batch|
      settings = batch.to_a
      latest_interactions = latest_interactions_for(settings)
      deliveries = settings.flat_map do |setting|
        latest_interaction_on = latest_interactions[setting.friend_id]
        next [] unless setting.due?(on: through, latest_interaction_on:)

        reminder_on = setting.next_suggestion_on(latest_interaction_on:)
        delivery_attributes_for(setting, [ [ reminder_on, reminder_on ] ])
      end

      record_deliveries(deliveries)
    end
  end

  def schedule_entry_reminders(during:)
    process_in_batches(entry_reminders, preload: :entry) do |reminder|
      reminder_dates_during(reminder, during:)
    end
  end

  def schedule_birthday_reminders(during:)
    return 0 unless user.birthday_reminders_enabled?

    process_in_batches(birthdays, preload: :friend) do |birthday|
      birthday_reminder_dates_during(birthday, during:)
    end
  end

  def process_in_batches(relation, preload:)
    relation.in_batches(of: batch_size).sum do |batch|
      deliveries = batch.preload(preload).flat_map do |source|
        delivery_attributes_for(source, yield(source))
      end

      record_deliveries(deliveries)
    end
  end

  def keep_in_touch_settings
    KeepInTouchSetting.joins(:friend).where(friends: { user_id: user.id }).where.not(enabled_on: nil)
  end

  def entry_reminders
    EntryReminder.joins(entry: :friend)
      .where(friends: { user_id: user.id })
      .where.not(entries: { type: "Entry::Birthday" })
  end

  def birthdays
    Entry::Birthday.joins(:friend).where(friends: { user_id: user.id })
  end

  def latest_interactions_for(settings)
    Interaction.where(friend_id: settings.map(&:friend_id)).group(:friend_id).maximum(:occurred_on)
  end

  def reminder_dates_during(reminder, during:)
    reminder_on = reminder.next_reminder_on(on: during.begin)
    latest_dates = nil

    while reminder_on && reminder_on <= during.end
      latest_dates = [ reminder_on, reminder_on + reminder.lead_days ]
      break if reminder.one_time?

      reminder_on = reminder.next_reminder_on(on: reminder_on.next_day)
    end

    latest_dates ? [ latest_dates ] : []
  end

  def birthday_reminder_dates_during(birthday, during:)
    lead_days = user.birthday_reminder_lead_days
    occurrence_on = birthday.next_occurrence_on(on: during.begin + lead_days)
    latest_dates = nil

    while (reminder_on = occurrence_on - lead_days) <= during.end
      latest_dates = [ reminder_on, occurrence_on ]
      occurrence_on = birthday.next_occurrence_on(on: occurrence_on.next_day)
    end

    latest_dates ? [ latest_dates ] : []
  end

  def enabled_channels
    ReminderDelivery::CHANNELS.select { user.reminder_channel_enabled?(_1) }
  end

  def delivery_attributes(source:, channel:, reminder_on:, occurrence_on:)
    {
      user_id: user.id,
      source_type: source.class.polymorphic_name,
      source_id: source.id,
      channel:,
      reminder_on:,
      occurrence_on:
    }
  end

  def delivery_attributes_for(source, dates)
    dates.flat_map do |reminder_on, occurrence_on|
      enabled_channels.map do |channel|
        delivery_attributes(source:, channel:, reminder_on:, occurrence_on:)
      end
    end
  end

  def record_deliveries(attributes)
    return 0 if attributes.empty?

    # The unique ledger index makes retries and overlapping scheduler runs safe without per-source locks.
    ReminderDelivery.transaction do
      inserted_count = ReminderDelivery.insert_all(
        attributes,
        unique_by: :index_reminder_deliveries_on_source_date_and_channel,
        record_timestamps: true
      ).length

      inserted_count + reactivate_canceled_deliveries(attributes)
    end
  end

  def reactivate_canceled_deliveries(attributes)
    attributes_by_key = attributes.index_by { delivery_key(_1) }
    candidates = ReminderDelivery.where(
      status: ReminderDelivery::CANCELED_STATUS,
      source_type: attributes.pluck(:source_type).uniq,
      source_id: attributes.pluck(:source_id).uniq,
      reminder_on: attributes.pluck(:reminder_on).uniq,
      channel: attributes.pluck(:channel).uniq
    )

    candidates.count do |delivery|
      current_attributes = attributes_by_key[delivery_key(delivery.attributes.symbolize_keys)]
      next false unless current_attributes

      delivery.update_columns(
        status: ReminderDelivery::PENDING_STATUS,
        occurrence_on: current_attributes.fetch(:occurrence_on),
        canceled_at: nil,
        claimed_at: nil,
        claim_token: nil,
        updated_at: Time.current
      )
      true
    end
  end

  def delivery_key(attributes)
    attributes.values_at(:source_type, :source_id, :reminder_on, :channel)
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end
end
