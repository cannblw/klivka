require "test_helper"

class TogglePillGroupComponentTest < ViewComponent::TestCase
  class FakeForm
    def radio_button(field, value, **options)
      checked = options[:checked] ? "checked" : ""
      disabled = options[:disabled] ? "disabled" : ""
      "<input type='radio' name='#{field}' value='#{value}' #{checked} #{disabled} class='#{options[:class]}' />".html_safe
    end
  end

  test "renders all choices as labeled radio pills" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :locale, choices: [ [ :en, "English" ], [ :es, "Spanish" ] ], selected: :en
    )

    assert_selector "label", count: 2
    assert_selector "label", text: "English"
    assert_selector "label", text: "Spanish"
  end

  test "applies active styling to the selected pill" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :theme, choices: [ [ :light, "Light" ], [ :dark, "Dark" ] ], selected: :light
    )

    assert_selector "label.border-brand-focus", text: "Light"
    assert_selector "label.border-stone-200", text: "Dark"
  end

  test "marks the selected radio button as checked" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :locale, choices: [ [ :en, "English" ], [ :es, "Spanish" ] ], selected: :es
    )

    assert_selector "input[value='es'][checked]"
    assert_no_selector "input[value='en'][checked]"
  end

  test "disables all radio buttons when the group is disabled" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :locale, choices: [ [ :en, "English" ], [ :es, "Spanish" ] ], selected: :en, disabled: true
    )

    assert_selector "input[disabled]", count: 2
  end

  test "makes the disabled explanation available to keyboard users" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :locale, choices: [ [ :en, "English" ] ], selected: :en,
      disabled: true, disabled_tooltip: "Not available", disabled_tooltip_id: "locale-explanation"
    )

    assert_selector "div[role='group'][tabindex='0'][aria-disabled='true'][aria-describedby='locale-explanation']"
    assert_selector "span#locale-explanation", text: "Not available"
  end

  test "does not render a tooltip when the group is enabled" do
    render_inline TogglePillGroupComponent.new(
      form: FakeForm.new, field: :locale, choices: [ [ :en, "English" ] ], selected: :en,
      disabled_tooltip: "Not available"
    )

    assert_no_selector "span.pointer-events-none"
    assert_no_selector "div[tabindex]"
  end
end
