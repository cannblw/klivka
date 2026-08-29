require "test_helper"

class InteractionContactMethodPickerComponentTest < ViewComponent::TestCase
  test "renders enabled contact methods as ordered icon choices" do
    interaction = people(:ada).interactions.new
    enabled_methods = users(:one).contact_methods.enabled.ordered.to_a
    form = ActionView::Helpers::FormBuilder.new(
      :interaction, interaction, vc_test_controller.view_context, {}
    )

    render_inline InteractionContactMethodPickerComponent.new(
      form:, interaction:, contact_methods: enabled_methods
    )

    assert_selector "fieldset[role='radiogroup']", count: 0
    assert_selector "fieldset legend", text: "How you connected"
    assert_selector "[role='radiogroup']"
    assert_selector "input[type='radio'][value=''][checked]"
    assert_selector "input[type='radio'][value='#{contact_methods(:one_whatsapp).id}'] + span img"
    values = page.all("input[type='radio']").map { |input| input["value"] }
    assert_equal [ "", *enabled_methods.map { |contact_method| contact_method.id.to_s } ], values
  end

  test "keeps a retired historical method available while editing" do
    interaction = Interaction.new(
      person: people(:ada),
      contact_method_name: "Carrier pigeon",
      contact_method_icon_library: "material_icons",
      contact_method_icon_name: "email"
    )
    form = ActionView::Helpers::FormBuilder.new(
      :interaction, interaction, vc_test_controller.view_context, {}
    )

    render_inline InteractionContactMethodPickerComponent.new(
      form:, interaction:, contact_methods: users(:one).contact_methods.enabled.ordered.to_a
    )

    assert_selector "input[type='radio'][value='#{Interaction::PRESERVE_CONTACT_METHOD_VALUE}'][checked] + span", text: "Carrier pigeon"
  end
end
