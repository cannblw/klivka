require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  test "defaults to a primary medium button" do
    render_inline(ButtonComponent.new) { "Save" }

    assert_selector "button[type='button'].bg-indigo-600.cursor-pointer", text: "Save"
  end

  test "ghost variant and small size" do
    render_inline(ButtonComponent.new(variant: :ghost, size: :sm)) { "Cancel" }

    assert_selector "button.text-gray-600.px-3", text: "Cancel"
    assert_no_selector ".bg-indigo-600"
  end

  test "passes through type, data attributes and extra classes" do
    render_inline(ButtonComponent.new(type: :submit, class: "w-full", data: { action: "dialog#open" })) { "Go" }

    assert_selector "button[type='submit'][data-action='dialog#open'].w-full", text: "Go"
  end
end
