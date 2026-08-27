require "test_helper"

class BatchPersonCandidateComponentTest < ViewComponent::TestCase
  test "batch person candidate renders an editable selected name" do
    candidate = BatchPersonCreation::Candidate.new(
      id: "2", name: "Marie Curie", selected: true, duplicate: false, errors: []
    )

    render_inline BatchPersonCandidateComponent.new(candidate:)

    assert_selector "input[type='checkbox'][name='batch_person_creation[candidates][2][selected]'][checked]"
    assert_selector "input[type='text'][name='batch_person_creation[candidates][2][name]'][value='Marie Curie']"
    assert_selector "label[for='batch-person-candidate-2-selected']"
    assert_selector "label[for='batch-person-candidate-2-name']"
  end

  test "batch person candidate associates duplicate guidance and errors with the name" do
    candidate = BatchPersonCreation::Candidate.new(
      id: "2", name: "", selected: true, duplicate: true, errors: [ "Name can't be blank" ]
    )

    render_inline BatchPersonCandidateComponent.new(candidate:)

    assert_selector "input[aria-invalid='true'][aria-describedby~='batch-person-candidate-2-duplicate'][aria-describedby~='batch-person-candidate-2-errors']"
    assert_selector "#batch-person-candidate-2-duplicate[role='note']"
    assert_selector "#batch-person-candidate-2-errors", text: /can't be blank/
  end
end
