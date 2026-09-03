class ContactReminderComponent < ViewComponent::Base
  def initialize(person:, reminder:, **options)
    @person = person
    @reminder = reminder
    @extra_classes = options.delete(:class)
    @options = options
  end

  private

  attr_reader :person, :reminder, :options

  delegate :setting, to: :reminder

  def classes
    [
      "border-t border-stone-200 pt-5 dark:border-stone-700",
      @extra_classes
    ].compact.join(" ")
  end

  def enabled?
    reminder.enabled?
  end

  def due?
    reminder.due?(on: Date.current)
  end

  def snoozed?
    reminder.snoozed?
  end

  def cadence_options
    KeepInTouchSetting::CADENCES.map { |cadence| [ t("contact_reminder.cadences.#{cadence}"), cadence ] }
  end

  def selected_cadence
    reminder.cadence || setting&.cadence || ContactReminder::DEFAULT_CADENCE
  end

  def next_suggestion_on
    reminder.next_suggestion_on
  end

  def cadence_label
    cadence_label_for(reminder.cadence)
  end

  def account_cadence_label
    cadence_label_for(person.user.contact_reminder_cadence)
  end

  def activation_form_action
    setting ? enable_person_keep_in_touch_setting_path(person) : person_keep_in_touch_setting_path(person)
  end

  def activation_form_method
    setting ? :patch : :post
  end

  def frequency_form_method
    setting ? :patch : :post
  end

  def inherited?
    reminder.inherited?
  end

  def opted_out?
    reminder.opted_out?
  end

  def account_reminder_enabled?
    person.user.contact_reminders_enabled?
  end

  def settings_summary
    key = if reminder.overridden?
      "contact_reminder.change_custom_reminder"
    elsif inherited?
      "contact_reminder.set_custom_reminder"
    elsif opted_out? && account_reminder_enabled?
      "contact_reminder.choose_custom_reminder"
    else
      "contact_reminder.set_reminder"
    end

    t(key)
  end

  def use_default_label
    t("contact_reminder.use_default_reminder_with_cadence", frequency: account_cadence_label.downcase)
  end

  def cadence_label_for(cadence)
    t("contact_reminder.cadences.#{cadence}")
  end
end
