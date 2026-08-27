class BatchPersonCreation
  include ActiveModel::Model

  Candidate = Struct.new(:id, :name, :selected, :duplicate, :errors, keyword_init: true)

  attr_reader :user, :candidates, :created_people, :names

  validate :validate_candidates

  def self.preview(user:, names:)
    candidates = names.to_s.lines.filter_map.with_index do |name, index|
      normalized_name = name.squish
      next if normalized_name.blank?

      Candidate.new(id: index.to_s, name: normalized_name, selected: true, duplicate: false, errors: [])
    end

    mark_duplicates(user:, candidates:)
    new(user:, candidates:, names:)
  end

  def self.from_review(user:, candidates:)
    candidates = candidates.map.with_index do |attributes, index|
      Candidate.new(
        id: index.to_s,
        name: attributes.fetch("name", "").squish,
        selected: ActiveModel::Type::Boolean.new.cast(attributes["selected"]),
        duplicate: false,
        errors: []
      )
    end

    mark_duplicates(user:, candidates:)
    new(user:, candidates:)
  end

  def self.mark_duplicates(user:, candidates:)
    existing_names = user.people.pluck(:name).to_set { |name| PersonNameNormalizer.call(name) }
    candidate_names = candidates.map { |candidate| PersonNameNormalizer.call(candidate.name) }
    repeated_names = candidate_names.tally.select { |_name, count| count > 1 }.keys.to_set

    candidates.zip(candidate_names).each do |candidate, normalized_name|
      candidate.duplicate = existing_names.include?(normalized_name) || repeated_names.include?(normalized_name)
    end
  end
  private_class_method :mark_duplicates

  def initialize(user:, candidates:, names: nil)
    @user = user
    @candidates = candidates
    @names = names
    @created_people = []
    super()
  end

  def save
    return false unless valid?

    @created_people = Person.transaction do
      selected_candidates.map { |candidate| user.people.create!(name: candidate.name) }
    end
    true
  end

  def selected_count
    selected_candidates.size
  end

  def skipped_count
    candidates.size - selected_count
  end

  def duplicate_count
    candidates.count(&:duplicate)
  end

  def validate_candidates
    candidates.each { |candidate| candidate.errors = [] }

    if selected_candidates.empty?
      errors.add(:candidates, :blank)
      return
    end

    selected_candidates.each do |candidate|
      person = user.people.new(name: candidate.name)
      next if person.valid?

      candidate.errors = person.errors.full_messages_for(:name)
      errors.add(:candidates, :invalid)
    end
  end

  private

  def selected_candidates
    candidates.select(&:selected)
  end
end
