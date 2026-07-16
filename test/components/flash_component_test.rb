require "test_helper"

class FlashComponentTest < ViewComponent::TestCase
  test "notice renders green with a status role" do
    render_inline FlashComponent.new(kind: :notice, message: "Saved.")

    assert_text "Saved."
    assert_selector "[role='status'].bg-emerald-600"
    assert_selector "button[aria-label='Dismiss']"
    assert_selector "[data-controller='toast'] circle[data-toast-target='ring']"
  end

  test "alert renders red with an alert role" do
    render_inline FlashComponent.new(kind: :alert, message: "Nope.")

    assert_text "Nope."
    assert_selector "[role='alert'].bg-red-500"
  end
end
