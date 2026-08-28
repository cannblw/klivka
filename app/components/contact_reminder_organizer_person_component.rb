class ContactReminderOrganizerPersonComponent < ViewComponent::Base
  with_collection_parameter :person

  def initialize(person:)
    @person = person
    @reminder = ContactReminder.for(person)
  end

  private

  attr_reader :person, :reminder

  def selected_value
    return ContactReminder::DEFAULT_SELECTION if reminder.setting.nil?
    return ContactReminder::OFF_SELECTION if reminder.opted_out?

    reminder.cadence
  end

  def selection_id
    "contact-reminder-selection-#{person.id}"
  end

  def choices
    [
      [ default_choice_label, ContactReminder::DEFAULT_SELECTION ],
      *ContactReminder::CADENCES.map { |cadence| [ t("contact_reminder.cadences.#{cadence}"), cadence ] },
      [ t("contact_reminders.organizer.off"), ContactReminder::OFF_SELECTION ]
    ]
  end

  def default_choice_label
    if person.user.contact_reminders_enabled?
      t("contact_reminders.organizer.default_with_cadence",
        cadence: t("contact_reminder.cadences.#{person.user.contact_reminder_cadence}"))
    else
      t("contact_reminders.organizer.default_off")
    end
  end

  def state_label
    if reminder.inherited?
      t("contact_reminders.organizer.states.default",
        cadence: t("contact_reminder.cadences.#{reminder.cadence}"))
    elsif reminder.overridden?
      t("contact_reminders.organizer.states.custom",
        cadence: t("contact_reminder.cadences.#{reminder.cadence}"))
    elsif reminder.opted_out?
      t("contact_reminders.organizer.states.off")
    else
      t("contact_reminders.organizer.states.default_off")
    end
  end
end
