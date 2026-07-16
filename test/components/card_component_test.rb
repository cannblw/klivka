require "test_helper"

class CardComponentTest < ViewComponent::TestCase
  test "renders the card container with content" do
    render_inline(CardComponent.new) { "<p>Hello</p>".html_safe }

    assert_selector "div.rounded-xl.border.border-gray-200.bg-white"
    assert_text "Hello"
  end
end
