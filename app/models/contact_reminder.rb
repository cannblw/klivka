class ContactReminder
  CADENCE_INTERVALS = {
    "daily" => 1.day,
    "weekly" => 1.week,
    "biweekly" => 2.weeks,
    "monthly" => 1.month,
    "quarterly" => 3.months,
    "yearly" => 1.year
  }.freeze
  CADENCES = CADENCE_INTERVALS.keys.freeze
  DEFAULT_CADENCE = "weekly"
  GLOBAL_DEFAULT_CADENCE = "monthly"
  DEFAULT_SELECTION = "default"
  OFF_SELECTION = "off"
  SNOOZE_DAYS = 7
  LATEST_INTERACTION_UNSPECIFIED = Object.new.freeze

  attr_reader :person, :setting, :user

  def self.for(person, user: person.user)
    new(person:, setting: person.keep_in_touch_setting, user:)
  end

  def initialize(person:, setting: person.keep_in_touch_setting, user: person.user)
    @person = person
    @setting = setting
    @user = user
  end

  def enabled?
    overridden? || inherited?
  end

  def inherited?
    setting.nil? && user.contact_reminders_enabled?
  end

  def overridden?
    setting&.enabled? || false
  end

  def opted_out?
    setting.present? && !setting.enabled?
  end

  def cadence
    return setting.cadence if overridden?

    user.contact_reminder_cadence if inherited?
  end

  def enabled_on
    return setting.enabled_on if overridden?

    user.contact_reminders_enabled_on if inherited?
  end

  def next_suggestion_on(latest_interaction_on: LATEST_INTERACTION_UNSPECIFIED)
    return unless enabled?

    latest_interaction_on = person.interactions.maximum(:occurred_on) if latest_interaction_on.equal?(LATEST_INTERACTION_UNSPECIFIED)
    [ cadence_date(latest_interaction_on:), person.contact_reminder_snoozed_until ].compact.max
  end

  def due?(on:, latest_interaction_on: LATEST_INTERACTION_UNSPECIFIED)
    next_suggestion_on(latest_interaction_on:)&.<= on
  end

  def snoozed?(latest_interaction_on: LATEST_INTERACTION_UNSPECIFIED)
    return false unless enabled? && person.contact_reminder_snoozed_until.present?

    latest_interaction_on = person.interactions.maximum(:occurred_on) if latest_interaction_on.equal?(LATEST_INTERACTION_UNSPECIFIED)
    person.contact_reminder_snoozed_until > cadence_date(latest_interaction_on:)
  end

  def snooze!(on:)
    person.update!(contact_reminder_snoozed_until: on + SNOOZE_DAYS.days)
    setting&.touch
  end

  def use_default!
    person.transaction do
      setting&.destroy!
      person.update!(contact_reminder_snoozed_until: nil)
      @setting = nil
    end
  end

  def override!(cadence:, on:)
    person.transaction do
      @setting ||= person.build_keep_in_touch_setting
      setting.cadence = cadence
      setting.enabled_on ||= on
      setting.save!
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def opt_out!
    effective_cadence = cadence || setting&.cadence || DEFAULT_CADENCE

    person.transaction do
      @setting ||= person.build_keep_in_touch_setting
      setting.update!(cadence: effective_cadence, enabled_on: nil)
      person.update!(contact_reminder_snoozed_until: nil)
    end
  end

  def clear_snooze_for_latest_interaction!(interaction)
    return unless enabled? && person.contact_reminder_snoozed_until.present?
    return if interaction.occurred_on < enabled_on
    return unless interaction.occurred_on == person.interactions.maximum(:occurred_on)

    person.update!(contact_reminder_snoozed_until: nil)
    setting&.touch
  end

  private

  def cadence_date(latest_interaction_on:)
    base_date = [ enabled_on, latest_interaction_on ].compact.max
    base_date + CADENCE_INTERVALS.fetch(cadence)
  end
end
