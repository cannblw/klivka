class EntryReminderFieldsComponent < ViewComponent::Base
  def initialize(form:, entry:)
    @form = form
    @entry = entry
    @reminder = entry.entry_reminder
    @reminder_enabled = @reminder.present? && !@reminder.marked_for_destruction?
  end

  private

  attr_reader :form, :entry, :reminder_enabled

  def reminder
    @reminder ||= EntryReminder.new(EntryReminder.default_lead_attributes_for(entry))
  end

  def lead_unit_options
    EntryReminder::LEAD_UNITS.keys.map { |unit| [ t("entries.reminder.lead_units.#{unit}"), unit ] }
  end
end
