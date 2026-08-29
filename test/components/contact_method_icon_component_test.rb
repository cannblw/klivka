require "test_helper"

class ContactMethodIconComponentTest < ViewComponent::TestCase
  test "renders a decorative Material Icon" do
    render_inline ContactMethodIconComponent.new(
      icon_library: "material_icons", icon_name: "call", size: 18
    )

    assert_selector "span.material-icons[aria-hidden='true']", text: "call"
    assert_selector "span[style='font-size: 18px']"
  end

  test "renders a decorative Simple Icons image from the pinned library version" do
    render_inline ContactMethodIconComponent.new(
      icon_library: "simple_icons", icon_name: "whatsapp", size: 18
    )

    assert_selector "img[src='https://cdn.jsdelivr.net/npm/simple-icons@16.29.0/icons/whatsapp.svg'][width='18'][height='18'][aria-hidden='true'][alt='']"
  end

  test "renders nothing for an unknown icon" do
    render_inline ContactMethodIconComponent.new(icon_library: "unknown", icon_name: "call")

    assert_no_selector "span, img"
  end
end
