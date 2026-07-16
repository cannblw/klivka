require "test_helper"

class CardComponentTest < ViewComponent::TestCase
  test "renders the card container with content" do
    render_inline(CardComponent.new) { "<p>Hello</p>".html_safe }

    assert_selector "div.rounded-xl.border.border-stone-200.bg-stone-50"
    assert_text "Hello"
  end
end
