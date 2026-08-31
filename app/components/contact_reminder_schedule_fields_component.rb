class ContactReminderScheduleFieldsComponent < ViewComponent::Base
  include FormStyling

  def initialize(scope:, cadence:, first_reminder_on:, today:, id_prefix:)
    @scope = scope
    @cadence = cadence
    @today = today
    @first_reminder_on = first_reminder_on || default_first_reminder_on
    @id_prefix = id_prefix
  end

  private

  attr_reader :scope, :cadence, :first_reminder_on, :today, :id_prefix

  def field_name(field)
    "#{scope}[#{field}]"
  end

  def field_id(field, cadence = nil)
    [ id_prefix, cadence, field.to_s.dasherize ].compact.join("-")
  end

  def weekday_options
    I18n.t("date.day_names").each_with_index.map { |name, index| [ name, index ] }
  end

  def month_options
    I18n.t("date.month_names").each_with_index.filter_map { |name, index| [ name, index ] if name }
  end

  def day_options
    (1..31).map { |day| [ day, day ] }
  end

  def input_classes
    FormStyling::INPUT_CLASSES
  end

  def default_first_reminder_on
    return today.tomorrow unless ContactReminder::CADENCES.include?(cadence)

    ContactReminder.default_first_reminder_on(cadence:, on: today)
  end
end
