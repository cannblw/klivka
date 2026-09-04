require "test_helper"

class DialogComponentTest < ViewComponent::TestCase
  test "renders the shared accessible dialog shell" do
    render_inline DialogComponent.new(
      id: "person-dialog",
      labelledby: "person-dialog-title",
      describedby: "person-dialog-description"
    ) do
      "Dialog content"
    end

    assert_selector "dialog#person-dialog[aria-labelledby='person-dialog-title'][aria-describedby='person-dialog-description']"
    assert_no_selector "dialog[data-controller], dialog[data-action], dialog[data-dialog-target]"
    assert_selector "dialog.w-full.max-w-sm"
  end

  test "supports the large dialog size and caller-owned behavior" do
    render_inline DialogComponent.new(
      size: :lg,
      labelledby: "example-heading",
      data: { action: "close->example#reset", example_target: "dialog" }
    ) { "Content" }

    assert_selector "dialog.max-w-lg[data-example-target='dialog']"
    assert_selector "dialog[data-action='close->example#reset']"
  end

  test "rejects unknown dialog sizes" do
    assert_raises(ArgumentError) { DialogComponent.new(size: :wide, labelledby: "heading") }
  end

  test "requires an accessible name" do
    assert_raises(ArgumentError) { DialogComponent.new }
  end
end
