class VcardImport::DuplicateMarker
  def self.call(user:, candidates:)
    new(user:, candidates:).call
  end

  def initialize(user:, candidates:)
    @user = user
    @candidates = candidates
  end

  def call
    existing_names = user.people.pluck(:name).map { |name| PersonNameNormalizer.call(name) }.index_with(true)
    candidate_names = candidates.map { |candidate| PersonNameNormalizer.call(candidate.fetch("name")) }
    repeated_names = candidate_names.tally.select { |_name, count| count > 1 }
    duplicate_names = existing_names.merge(repeated_names)

    candidates.zip(candidate_names).map do |candidate, candidate_name|
      duplicate_names.key?(candidate_name) ? candidate.merge("duplicate" => true) : candidate
    end
  end

  private

  attr_reader :user, :candidates
end
