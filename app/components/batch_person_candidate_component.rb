class BatchPersonCandidateComponent < ViewComponent::Base
  include FormStyling

  with_collection_parameter :candidate

  def initialize(candidate:)
    @candidate = candidate
  end

  private

  attr_reader :candidate

  def field_name(field)
    "batch_person_creation[candidates][#{candidate.id}][#{field}]"
  end

  def dom_id
    "batch-person-candidate-#{candidate.id}"
  end

  def description_ids
    [ ("#{dom_id}-duplicate" if candidate.duplicate), ("#{dom_id}-errors" if candidate.errors.any?) ].compact.join(" ").presence
  end
end
