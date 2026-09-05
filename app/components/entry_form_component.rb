class EntryFormComponent < ViewComponent::Base
  include FormStyling

  def initialize(entry:, person:)
    @entry = entry
    @person = person
  end

  private

  attr_reader :entry, :person

  def entry_supports_reminders?
    EntryReminder.eligible_entry?(entry)
  end

  def form_controllers
    [ "unsaved-changes", ("reminder-date" if entry_supports_reminders?) ].compact.join(" ")
  end

  def reminder_date_values
    {
      reminder_date_yearly_recurrence_value: EntryReminder::YEARLY_RECURRENCE,
      unsaved_changes_title_value: t("discard_changes.title"),
      unsaved_changes_body_value: t("discard_changes.body"),
      unsaved_changes_confirm_label_value: t("discard_changes.discard"),
      unsaved_changes_cancel_label_value: t("discard_changes.keep_editing")
    }
  end
end
