class EntryCardComponent < ViewComponent::Base
  def initialize(entry:, friend:)
    @entry = entry
    @friend = friend
  end

  private

  attr_reader :entry, :friend

  def kind_key
    entry.type.demodulize.underscore
  end

  def reminder
    entry.entry_reminder
  end

  def reminder_summary
    t("entries.reminder.summary.#{reminder.recurrence}", timing: reminder_timing)
  end

  def reminder_timing
    return t("entries.reminder.timing.same_day") if reminder.lead_value.zero?

    t("entries.reminder.timing.#{reminder.lead_unit}", count: reminder.lead_value)
  end
end
