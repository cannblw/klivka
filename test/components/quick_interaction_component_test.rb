require "test_helper"

class QuickInteractionComponentTest < ViewComponent::TestCase
  test "opens an unsaved interaction form" do
    friend = friends(:ada)
    interaction = friend.interactions.new(occurred_on: Date.current)

    render_inline QuickInteractionComponent.new(friend: friend, interaction: interaction)

    path = Rails.application.routes.url_helpers.friend_interactions_path(friend)
    assert_selector "button[type='button'][aria-controls='#{QuickInteractionComponent::DOM_ID}']", text: "Contacted today"
    assert_selector "[data-controller~='dialog'][data-dialog-open-value='false'] dialog##{QuickInteractionComponent::DOM_ID}"
    assert_selector "form[action='#{path}']"
    assert_selector "input[name='context'][value='quick_log']", visible: :all
    assert_selector "input#interaction_occurred_on[type='date'][required]"
    assert_selector "input#interaction_occurred_on[max='#{Date.current}']"
    assert_selector "select[name='interaction[contact_method]'] option", text: "In person"
    assert_selector "textarea[name='interaction[note]']"
  end

  test "reopens an invalid interaction with errors and submitted details" do
    interaction = Interaction.new(
      friend: friends(:ada),
      occurred_on: Date.tomorrow,
      contact_method: "call",
      note: "Keep this note"
    )
    interaction.validate

    render_inline QuickInteractionComponent.new(friend: friends(:ada), interaction: interaction, open: true)

    assert_selector "[data-controller~='dialog'][data-dialog-open-value='true'] dialog"
    assert_text "Date must not be in the future"
    assert_selector "select[name='interaction[contact_method]'] option[selected][value='call']"
    assert_selector "textarea", text: "Keep this note"
  end
end
