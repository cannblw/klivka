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
    assert_selector "input#quick-interaction-dialog_interaction_occurred_on[type='date'][required]"
    assert_selector "input#quick-interaction-dialog_interaction_occurred_on[max='#{Date.current}']"
    assert_selector "fieldset legend", text: "How you connected"
    assert_selector "input[type='radio'][name='interaction[contact_method_id]'][value='#{contact_methods(:one_in_person).id}']"
    assert_no_selector "input[type='radio'][name='interaction[contact_method_id]'][value='#{contact_methods(:one_wechat).id}']"
    option_values = page.all("input[type='radio'][name='interaction[contact_method_id]']").map { |option| option["value"] }
    assert_equal [ "", *users(:one).contact_methods.enabled.ordered.ids.map(&:to_s) ], option_values
    assert_selector "textarea[name='interaction[note]']"
  end

  test "supports a unique dialog and reminders return context" do
    person = people(:ada)
    interaction = person.interactions.new(occurred_on: Date.current)

    render_inline QuickInteractionComponent.new(
      person:, interaction:, time_zone: "Europe/Madrid",
      dom_id: "contact-dialog-123", button_label: "Contact now", return_to: "reminders"
    )

    assert_selector "button[aria-controls='contact-dialog-123']", text: "Contact now"
    assert_selector "dialog#contact-dialog-123[aria-labelledby='contact-dialog-123-heading']"
    assert_selector "input#contact-dialog-123_interaction_occurred_on"
    assert_selector "input[name='return_to'][value='reminders']", visible: :hidden
  end

  test "reopens an invalid interaction with errors and submitted details" do
    interaction = Interaction.new(
      person: people(:ada),
      occurred_on: Date.tomorrow,
      contact_method_name: "Call",
      contact_method_icon_library: "material_icons",
      contact_method_icon_name: "call",
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
    assert_selector "input[type='radio'][name='interaction[contact_method_id]'][checked][value='#{contact_methods(:one_call).id}']"
    assert_selector "textarea", text: "Keep this note"
  end
end
