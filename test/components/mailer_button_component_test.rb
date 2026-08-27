require "test_helper"

class MailerButtonComponentTest < ViewComponent::TestCase
  test "renders an email-safe call-to-action link" do
    render_inline(MailerButtonComponent.new(label: "Open Ada", url: "https://example.com/people/ada"))

    assert_selector "table[role='presentation'] td[style*='text-align: center'] a[href='https://example.com/people/ada']", text: "Open Ada"
    assert_selector "table[style*='margin: 0 auto']", count: 1
    assert_selector "a[style*='background'][style*='text-decoration: none']", count: 0
    assert_selector "td[style*='background-color'] a[style*='text-decoration: none']", count: 1
  end
end
