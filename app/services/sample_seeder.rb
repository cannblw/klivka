require "faker"
require "set"

class SampleSeeder
  PERSON_COUNT = 100
  ARCHIVED_PERSON_COUNT = 2
  RANDOM_SEED = 20_260_802
  ENTRY_PATTERNS = [
    [],
    [],
    [],
    [ :phone ],
    [ :phone ],
    [ :phone ],
    [ :phone ],
    [ :phone ],
    [ :note, :email ],
    [ :note, :email ],
    [ :note ],
    [ :note ],
    [ :birthday ],
    [ :birthday ],
    [ :birthday ],
    [ :phone, :note, :email ],
    [ :phone, :note, :email ],
    [ :phone, :birthday ],
    [ :note, :birthday ],
    [ :phone, :note, :birthday, :email ]
  ].freeze
  PHONE_LABELS = %w[Home Mobile Work].freeze
  EMAIL_LABELS = [ "Personal", "Work", nil ].freeze
  CONTACT_SCENARIOS = {
    0 => [
      { kind: :phone, label: "Mobile" },
      { kind: :phone, label: "Work" },
      { kind: :phone, label: nil },
      { kind: :email, label: "Personal" },
      { kind: :email, label: "Work" },
      { kind: :email, label: nil }
    ],
    1 => [
      { kind: :phone, label: "Home" },
      { kind: :phone, label: "Mobile" },
      { kind: :phone, label: "Work" }
    ],
    2 => [
      { kind: :email, label: "Home" },
      { kind: :email, label: "Personal" },
      { kind: :email, label: "Work" }
    ],
    3 => [
      { kind: :email, label: "Work" }
    ]
  }.freeze

  def self.call(user:)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    previous_random = Faker::Config.random
    Faker::Config.random = Random.new(RANDOM_SEED)

    Person.transaction do
      clear_reminder_work
      @user.people.destroy_all

      person_names.each_with_index do |name, index|
        person = @user.people.create!(name: name)
        seed_entries(person, index, CONTACT_SCENARIOS[index])
      end

      @user.people.order(:id).last(ARCHIVED_PERSON_COUNT).each_with_index do |person, index|
        person.archive!(at: (ARCHIVED_PERSON_COUNT - index).days.ago)
      end

      seed_reminders
    end
  ensure
    Faker::Config.random = previous_random
  end

  private

  attr_reader :user

  def clear_reminder_work
    user.reminder_deliveries.delete_all
    user.contact_reminder_digests.delete_all
  end

  def seed_reminders
    today = user.local_date
    user.people.active.order(:id).first(3).each do |person|
      person.create_keep_in_touch_setting!(
        cadence: "daily",
        enabled_on: today.yesterday,
        first_reminder_on: today
      )
    end

    seed_birthday_reminder(on: today)
    seed_date_reminder(on: today)
    ReminderDelivery::Scheduler.call(user:)
  end

  def seed_birthday_reminder(on:)
    birthday, occurrence = Entry::Birthday.joins(:person)
      .where(people: { user_id: user.id, archived_at: nil })
      .map { |entry| [ entry, entry.next_occurrence_on(on:) ] }
      .min_by { |_, next_occurrence| next_occurrence }

    user.update!(
      birthday_reminders_enabled: true,
      birthday_reminder_lead_value: (occurrence - on).to_i,
      birthday_reminder_lead_unit: "days",
      reminder_in_app_enabled: true,
      reminders_scanned_through_on: nil
    )
  end

  def seed_date_reminder(on:)
    entry = user.people.active.order(:id).first.entries.create!(
      type: "Entry::Date",
      entry_date: on + 7.days,
      content: { "label" => "Sample date reminder" }
    )
    entry.create_entry_reminder!(lead_value: 7, lead_unit: "days", recurrence: "yearly")
  end

  def person_names
    names = Set.new
    names.add(Faker::Name.name) until names.length == PERSON_COUNT
    names.to_a
  end

  def seed_entries(person, index, scenario_entries)
    if scenario_entries
      scenario_entries.each do |entry|
        kind = entry.fetch(:kind)
        create_entry(person, kind:, content: scenario_content_for(kind, entry[:label]))
      end
    else
      entry_pattern(index).each do |kind|
        create_entry(person, kind:, content: content_for(kind))
      end
    end
  end

  def create_entry(person, kind:, content:)
    person.entries.create!(
      type: "Entry::#{kind.to_s.camelize}",
      content:,
      entry_date: kind == :birthday ? Faker::Date.birthday(min_age: 18, max_age: 80) : nil
    )
  end

  def entry_pattern(index)
    ENTRY_PATTERNS.fetch(index % ENTRY_PATTERNS.length)
  end

  def scenario_content_for(kind, label)
    content = case kind
    when :phone
      { "number" => Faker::PhoneNumber.phone_number }
    when :email
      { "email" => Faker::Internet.email }
    end
    content["label"] = label if label
    content
  end

  def content_for(kind)
    case kind
    when :phone
      { "number" => Faker::PhoneNumber.phone_number, "label" => PHONE_LABELS.fetch(Faker::Number.between(from: 0, to: PHONE_LABELS.length - 1)) }
    when :note
      { "text" => Faker::Lorem.sentence(word_count: Faker::Number.between(from: 4, to: 14)) }
    when :birthday
      {}
    when :email
      email_content = { "email" => Faker::Internet.email }
      label = EMAIL_LABELS.fetch(Faker::Number.between(from: 0, to: EMAIL_LABELS.length - 1))
      email_content["label"] = label if label
      email_content
    end
  end
end
