require "test_helper"

class DemoBannerComponentTest < ViewComponent::TestCase
  test "explains that the demo is shared and resets" do
    render_inline DemoBannerComponent.new

    assert_selector "aside[role='status']", text: "You're exploring a shared demo. Changes are visible to everyone and reset regularly."
  end
end
