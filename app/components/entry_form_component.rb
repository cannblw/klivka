class EntryFormComponent < ViewComponent::Base
  include FormStyling

  def initialize(entry:, friend:)
    @entry = entry
    @friend = friend
  end

  private

  attr_reader :entry, :friend

  def entry_supports_reminders?
    EntryReminder.eligible_entry?(entry)
  end

  def form_controllers
    [ "unsaved-changes", ("reminder-date" if entry_supports_reminders?) ].compact.join(" ")
  end

  def reminder_date_values
    { reminder_date_yearly_recurrence_value: EntryReminder::YEARLY_RECURRENCE }
  end
end
