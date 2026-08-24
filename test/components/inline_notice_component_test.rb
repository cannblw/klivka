require "test_helper"

class InlineNoticeComponentTest < ViewComponent::TestCase
  test "inline notice component renders persistent warning content" do
    render_inline(InlineNoticeComponent.new(class: "mt-4")) { "Review this information" }

    assert_selector "div[role='note'].bg-amber-50.mt-4", text: "Review this information"
  end

  test "inline notice component rejects an unknown kind" do
    assert_raises(KeyError) { InlineNoticeComponent.new(kind: :unknown) }
  end
end
