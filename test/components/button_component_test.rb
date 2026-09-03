require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  test "defaults to a primary medium button" do
    render_inline(ButtonComponent.new) { "Save" }

    assert_selector "button[type='button'].bg-amber-600.cursor-pointer", text: "Save"
  end

  test "ghost variant and small size" do
    render_inline(ButtonComponent.new(variant: :ghost, size: :sm)) { "Cancel" }

    assert_selector "button.text-stone-600.px-3", text: "Cancel"
    assert_no_selector ".bg-amber-600"
  end

  test "destructive variant uses the destructive palette" do
    render_inline(ButtonComponent.new(variant: :destructive)) { "Delete" }

    assert_selector "button.bg-red-600.hover\\:bg-red-500", text: "Delete"
  end

  test "passes through type, data attributes and extra classes" do
    render_inline(ButtonComponent.new(type: :submit, class: "w-full", data: { action: "dialog#open" })) { "Go" }

    assert_selector "button[type='submit'][data-action='dialog#open'].w-full", text: "Go"
  end

  test "styles disabled buttons consistently" do
    render_inline(ButtonComponent.new(disabled: true)) { "Save" }

    assert_selector "button[disabled][class~='disabled:cursor-not-allowed'][class~='disabled:opacity-50']"
  end
end
