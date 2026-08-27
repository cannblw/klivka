require "test_helper"

class QuickInteractionComponentTest < ViewComponent::TestCase
  test "opens an unsaved interaction form" do
    person = people(:ada)
    interaction = person.interactions.new(occurred_on: Date.current)

    render_inline QuickInteractionComponent.new(person: person, interaction: interaction, time_zone: "Europe/Madrid")

    path = Rails.application.routes.url_helpers.person_interactions_path(person)
    assert_selector "button[type='button'][aria-controls='#{QuickInteractionComponent::DOM_ID}']", text: "Contacted today"
    assert_selector "[data-controller~='dialog'][data-dialog-open-value='false'][data-action*='quick-interaction:open@window->dialog#open'][data-action*='quick-interaction:open@window->interaction-date#setCurrentDate'] dialog##{QuickInteractionComponent::DOM_ID}"
    assert_selector "[data-interaction-date-time-zone-value='Europe/Madrid']"
    assert_selector "form[action='#{path}']"
    assert_selector "input[name='context'][value='quick_log']", visible: :all
    assert_selector "input#interaction_occurred_on[type='date'][required]"
    assert_selector "input#interaction_occurred_on[max='#{Date.current}']"
    assert_selector "select[name='interaction[contact_method]'] option", text: "In person"
    assert_selector "textarea[name='interaction[note]']"
  end

  test "reopens an invalid interaction with errors and submitted details" do
    interaction = Interaction.new(
      person: people(:ada),
      occurred_on: Date.tomorrow,
      contact_method: "call",
      note: "Keep this note"
    )
    interaction.validate

    render_inline QuickInteractionComponent.new(
      person: people(:ada),
      interaction: interaction,
      time_zone: "Europe/Madrid",
      open: true
    )

    assert_selector "[data-controller~='dialog'][data-dialog-open-value='true'] dialog"
    assert_text "Date must not be in the future"
    assert_selector "select[name='interaction[contact_method]'] option[selected][value='call']"
    assert_selector "textarea", text: "Keep this note"
  end
end
