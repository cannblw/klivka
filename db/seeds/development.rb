require "faker"
require "set"

class DevelopmentSeedData
  FRIEND_COUNT = 100
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

    Friend.transaction do
      @user.friends.destroy_all

      friend_names.each_with_index do |name, index|
        friend = @user.friends.create!(name: name)
        seed_entries(friend, index, CONTACT_SCENARIOS[index])
      end
    end
  ensure
    Faker::Config.random = previous_random
  end

  private

  def friend_names
    names = Set.new
    names.add(Faker::Name.name) until names.length == FRIEND_COUNT
    names.to_a
  end

  def seed_entries(friend, index, scenario_entries)
    if scenario_entries
      scenario_entries.each do |entry|
        kind = entry.fetch(:kind)
        create_entry(friend, kind:, content: scenario_content_for(kind, entry[:label]))
      end
    else
      entry_pattern(index).each do |kind|
        create_entry(friend, kind:, content: content_for(kind))
      end
    end
  end

  def create_entry(friend, kind:, content:)
    friend.entries.create!(
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
