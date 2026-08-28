class DueContactRemindersQuery
  Result = Struct.new(:person, :reminder_on, keyword_init: true)

  def self.call(user:, on: user.local_date)
    new(user:, on:).call
  end

  def initialize(user:, on:, batch_size: Rails.application.config.x.reminder_scan_batch_size)
    @user = user
    @on = on
    @batch_size = batch_size
  end

  def call
    each_batch.to_a.flatten.sort_by do |result|
      [ result.reminder_on, PersonNameNormalizer.call(result.person.name), result.person.id ]
    end
  end

  def each_batch
    return enum_for(:each_batch) unless block_given?

    people.in_batches(of: batch_size) do |batch|
      batch_people = batch.preload(:keep_in_touch_setting).to_a
      latest_interactions = latest_interactions_for(batch_people)

      due_reminders = batch_people.filter_map do |person|
        reminder = ContactReminder.for(person, user:)
        latest_interaction_on = latest_interactions[person.id]
        reminder_on = reminder.next_suggestion_on(latest_interaction_on:)

        Result.new(person:, reminder_on:) if reminder_on&.<= on
      end

      yield due_reminders
    end
  end

  private

  attr_reader :user, :on, :batch_size

  def people
    relation = user.people.active
    return relation if user.contact_reminders_enabled?

    relation.joins(:keep_in_touch_setting).where.not(keep_in_touch_settings: { enabled_on: nil })
  end

  def latest_interactions_for(people)
    Interaction.where(person_id: people.map(&:id)).group(:person_id).maximum(:occurred_on)
  end
end
