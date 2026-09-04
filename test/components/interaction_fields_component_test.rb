require "test_helper"

class InteractionFieldsComponentTest < ViewComponent::TestCase
  test "renders the shared interaction fields with context-specific note height" do
    interaction = people(:ada).interactions.new(occurred_on: Date.current)

    render_inline InteractionFieldsComponent.new(
      form: form_for(interaction), interaction:, note_rows: 3
    )

    assert_selector "input[type='date'][name='interaction[occurred_on]'][required][max='#{Date.current}']"
    assert_selector "button[type='button'][data-action='interaction-date#openPicker'][aria-label]"
    assert_selector "input[type='radio'][name='interaction[contact_method_id]']",
      count: users(:one).contact_methods.enabled.count + 1
    assert_selector "textarea[name='interaction[note]'][rows='3']"
  end

  test "preserves submitted interaction values and errors" do
    interaction = people(:ada).interactions.new(occurred_on: Date.tomorrow, note: "Remember this")
    interaction.validate

    render_inline InteractionFieldsComponent.new(
      form: form_for(interaction), interaction:, note_rows: 4
    )

    assert_selector "input[name='interaction[occurred_on]'][value='#{Date.tomorrow}']"
    assert_selector ".text-red-600", text: /future/
    assert_selector "textarea[rows='4']", text: "Remember this"
  end

  private

  def form_for(interaction)
    ActionView::Helpers::FormBuilder.new(
      :interaction, interaction, vc_test_controller.view_context, {}
    )
  end
end
