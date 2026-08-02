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
    [ :note ],
    [ :note ],
    [ :note ],
    [ :note ],
    [ :birthday ],
    [ :birthday ],
    [ :birthday ],
    [ :phone, :note ],
    [ :phone, :note ],
    [ :phone, :birthday ],
    [ :note, :birthday ],
    [ :phone, :note, :birthday ]
  ].freeze
  PHONE_LABELS = %w[Home Mobile Work].freeze

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
        seed_entries(friend, index)
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

  def seed_entries(friend, index)
    entry_pattern(index).each do |kind|
      entry = friend.entries.find_or_initialize_by(type: "Entry::#{kind.to_s.camelize}")
      entry.content = content_for(kind)
      entry.entry_date = kind == :birthday ? Faker::Date.birthday(min_age: 18, max_age: 80) : nil
      entry.save!
    end
  end

  def entry_pattern(index)
    ENTRY_PATTERNS.fetch(index % ENTRY_PATTERNS.length)
  end

  def content_for(kind)
    case kind
    when :phone
      { "number" => Faker::PhoneNumber.phone_number, "label" => PHONE_LABELS.fetch(Faker::Number.between(from: 0, to: PHONE_LABELS.length - 1)) }
    when :note
      { "text" => Faker::Lorem.sentence(word_count: Faker::Number.between(from: 4, to: 14)) }
    when :birthday
      {}
    end
  end
end
