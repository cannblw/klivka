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
      "rounded-xl border border-stone-200 bg-stone-50 p-4 sm:p-5 dark:border-stone-700 dark:bg-stone-800",
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
    t("contact_reminder.cadences.#{reminder.cadence}")
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
end
