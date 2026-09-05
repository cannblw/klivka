class InAppRemindersQuery
  Result = Struct.new(:contacts, :birthdays, :dates, keyword_init: true) do
    def any?
      contacts.any? || birthdays.any? || dates.any?
    end
  end

  def self.call(user:, at: Time.current)
    new(user:, at:).call
  end

  def self.actionable?(user:, at: Time.current)
    new(user:, at:).actionable?
  end

  def initialize(user:, at:)
    @user = user
    @at = at
  end

  def call
    reconcile
    deliveries = pending_due_deliveries.preload(:source).to_a
    preload_source_people(deliveries)

    Result.new(
      contacts: sorted(deliveries.select { _1.source.is_a?(Person) }),
      birthdays: sorted(deliveries.select { _1.source.is_a?(Entry::Birthday) }),
      dates: sorted(deliveries.select { _1.source.is_a?(EntryReminder) })
    )
  end

  def actionable?
    reconcile
    pending_due_deliveries.exists?
  end

  private

  attr_reader :user, :at

  def reconcile
    ReminderDelivery::Reconciler.call(user:, at:, channel: ReminderDelivery::IN_APP_CHANNEL)
  end

  def pending_due_deliveries
    user.reminder_deliveries.where(
      channel: ReminderDelivery::IN_APP_CHANNEL,
      status: ReminderDelivery::PENDING_STATUS,
      claimed_at: nil,
      reminder_on: ..user.local_date(at:)
    )
  end

  def preload_source_people(deliveries)
    sources = deliveries.map(&:source)
    entry_reminders = sources.grep(EntryReminder)
    birthdays = sources.grep(Entry::Birthday)

    ActiveRecord::Associations::Preloader.new(records: entry_reminders, associations: { entry: :person }).call if entry_reminders.any?
    ActiveRecord::Associations::Preloader.new(records: birthdays, associations: :person).call if birthdays.any?
  end

  def sorted(deliveries)
    deliveries.sort_by do |delivery|
      person = person_for(delivery.source)
      [ delivery.reminder_on, delivery.occurrence_on, PersonNameNormalizer.call(person.name), delivery.id ]
    end
  end

  def person_for(source)
    case source
    when Person then source
    when EntryReminder then source.entry.person
    else source.person
    end
  end
end
