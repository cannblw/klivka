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
    user.update!(reminders_scanned_through_on: local_date)
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
    process_in_batches(keep_in_touch_settings, preload: :friend) do |setting|
      next [] unless setting.due?(on: through)

      reminder_on = setting.next_suggestion_on
      [ [ reminder_on, reminder_on ] ]
    end
  end

  def schedule_entry_reminders(during:)
    process_in_batches(entry_reminders, preload: :entry) do |reminder|
      reminder_dates_during(reminder, during:)
    end
  end

  def process_in_batches(relation, preload:)
    relation.in_batches(of: batch_size).sum do |batch|
      deliveries = batch.preload(preload).flat_map do |source|
        yield(source).flat_map do |reminder_on, occurrence_on|
          enabled_channels.map do |channel|
            delivery_attributes(source:, channel:, reminder_on:, occurrence_on:)
          end
        end
      end

      record_deliveries(deliveries)
    end
  end

  def keep_in_touch_settings
    KeepInTouchSetting.joins(:friend).where(friends: { user_id: user.id }).where.not(enabled_on: nil)
  end

  def entry_reminders
    EntryReminder.joins(entry: :friend).where(friends: { user_id: user.id })
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

  def enabled_channels
    [].tap do |channels|
      channels << "in_app" if user.reminder_in_app_enabled?
      channels << "email" if user.reminder_email_enabled?
    end
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

  def record_deliveries(attributes)
    return 0 if attributes.empty?

    # The unique ledger index makes retries and overlapping scheduler runs safe without per-source locks.
    ReminderDelivery.insert_all(
      attributes,
      unique_by: :index_reminder_deliveries_on_source_date_and_channel,
      record_timestamps: true
    ).length
  end

  def batch_size
    Rails.application.config.x.reminder_scan_batch_size
  end
end
