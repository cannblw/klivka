class ContactReminderSchedule
  PARAMETER_KEYS = %i[
    contact_reminder_schedule_changed
    first_reminder_weekday
    first_reminder_date
    first_reminder_day
    first_reminder_month
  ].freeze
  SELECTION_KEYS = (PARAMETER_KEYS - [ :contact_reminder_schedule_changed ]).freeze

  def initialize(cadence:, on:, attributes: {})
    @cadence = cadence
    @on = on
    @attributes = attributes.to_h.symbolize_keys.slice(*PARAMETER_KEYS)
  end

  def changed?
    attributes[:contact_reminder_schedule_changed] == "1"
  end

  def first_reminder_on
    return unless ContactReminder::CADENCES.include?(cadence)
    return default_first_reminder_on if selection.values.all?(&:blank?)

    resolve_first_reminder_on
  end

  def self.default_first_reminder_on(cadence:, on:)
    on + ContactReminder::CADENCE_INTERVALS.fetch(cadence)
  end

  def self.normalize_dates(cadence:, enabled_on:, first_reminder_on:, reset_first_reminder: false)
    return [ nil, nil ] if enabled_on.nil?
    return [ enabled_on, first_reminder_on ] unless ContactReminder::CADENCES.include?(cadence)

    first_reminder_on = nil if reset_first_reminder
    [ enabled_on, first_reminder_on || default_first_reminder_on(cadence:, on: enabled_on) ]
  end

  def self.dates_consistent?(cadence:, enabled_on:, first_reminder_on:)
    return true unless ContactReminder::CADENCES.include?(cadence)
    return true if enabled_on.nil? && first_reminder_on.nil?

    enabled_on.present? && first_reminder_on.present? && first_reminder_on > enabled_on
  end

  private

  attr_reader :attributes, :cadence, :on

  def selection
    attributes.slice(*SELECTION_KEYS)
  end

  def default_first_reminder_on
    self.class.default_first_reminder_on(cadence:, on:)
  end

  def resolve_first_reminder_on
    case cadence
    when "daily" then on.tomorrow
    when "weekly" then next_weekday(Integer(selection.fetch(:first_reminder_weekday), 10))
    when "biweekly" then Date.iso8601(selection.fetch(:first_reminder_date)).tap { raise_invalid unless _1 > on }
    when "monthly" then next_month_day(Integer(selection.fetch(:first_reminder_day), 10), interval: 1)
    when "quarterly" then next_cycle_date(interval: 3)
    when "yearly" then next_cycle_date(interval: 12)
    else raise_invalid
    end
  rescue ArgumentError, KeyError
    raise_invalid
  end

  def next_weekday(weekday)
    raise_invalid unless (0..6).cover?(weekday)

    days = (weekday - on.wday) % 7
    on + (days.zero? ? 7 : days).days
  end

  def next_month_day(day, interval:)
    raise_invalid unless (1..31).cover?(day)

    candidate = clamped_date(year: on.year, month: on.month, day:)
    next_month = on >> interval
    candidate <= on ? clamped_date(year: next_month.year, month: next_month.month, day:) : candidate
  end

  def next_cycle_date(interval:)
    month = Integer(selection.fetch(:first_reminder_month), 10)
    day = Integer(selection.fetch(:first_reminder_day), 10)
    raise_invalid unless (1..12).cover?(month) && (1..31).cover?(day)

    candidate = clamped_date(year: on.year, month:, day:)
    candidate = clamped_date(year: (candidate >> interval).year, month: (candidate >> interval).month, day:) while candidate <= on
    candidate
  end

  def clamped_date(year:, month:, day:)
    Date.new(year, month, [ day, Date.new(year, month, -1).day ].min)
  end

  def raise_invalid
    raise ContactReminder::InvalidSchedule
  end
end
