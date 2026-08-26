require "test_helper"

class BatchFriendCandidateComponentTest < ViewComponent::TestCase
  test "batch friend candidate renders an editable selected name" do
    candidate = BatchFriendCreation::Candidate.new(
      id: "2", name: "Marie Curie", selected: true, duplicate: false, errors: []
    )

    render_inline BatchFriendCandidateComponent.new(candidate:)

    assert_selector "input[type='checkbox'][name='batch_friend_creation[candidates][2][selected]'][checked]"
    assert_selector "input[type='text'][name='batch_friend_creation[candidates][2][name]'][value='Marie Curie']"
    assert_selector "label[for='batch-friend-candidate-2-selected']"
    assert_selector "label[for='batch-friend-candidate-2-name']"
  end

  test "batch friend candidate associates duplicate guidance and errors with the name" do
    candidate = BatchFriendCreation::Candidate.new(
      id: "2", name: "", selected: true, duplicate: true, errors: [ "Name can't be blank" ]
    )

    render_inline BatchFriendCandidateComponent.new(candidate:)

    assert_selector "input[aria-invalid='true'][aria-describedby~='batch-friend-candidate-2-duplicate'][aria-describedby~='batch-friend-candidate-2-errors']"
    assert_selector "#batch-friend-candidate-2-duplicate[role='note']"
    assert_selector "#batch-friend-candidate-2-errors", text: /can't be blank/
  end
end
