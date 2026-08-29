require "test_helper"

class ContactMethodIconPickerComponentTest < ViewComponent::TestCase
  test "renders optional whitelisted icon choices with an accessible legend" do
    contact_method = ContactMethod.new(icon_library: "simple_icons", icon_name: "signal")

    form = ActionView::Helpers::FormBuilder.new(
      :contact_method, contact_method, vc_test_controller.view_context, {}
    )

    render_inline ContactMethodIconPickerComponent.new(form:, selected: contact_method.icon)

    assert_selector "fieldset legend", text: "Icon"
    assert_selector "input[type='radio'][name='contact_method[icon]'][value='']"
    assert_selector "input[type='radio'][name='contact_method[icon]'][value='simple_icons:signal'][checked]"
    assert_selector "img[aria-hidden='true'][alt='']"
  end
end
