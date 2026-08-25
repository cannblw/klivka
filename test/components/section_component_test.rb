require "test_helper"

class SectionComponentTest < ViewComponent::TestCase
  test "renders a section container with content" do
    render_inline(SectionComponent.new) { "<p>Hello</p>".html_safe }

    assert_selector "section.rounded-xl.border.border-stone-200.bg-stone-50"
    assert_text "Hello"
  end

  test "renders title as an h2 heading" do
    render_inline(SectionComponent.new(title: "Account")) { "Body" }

    assert_selector "h2.text-lg.font-semibold", text: "Account"
  end

  test "uses the heading to label the section" do
    render_inline(SectionComponent.new(title: "Reminders", heading_id: "reminder-settings-heading")) { "Body" }

    assert_selector "section[aria-labelledby='reminder-settings-heading']"
    assert_selector "h2#reminder-settings-heading", text: "Reminders"
  end

  test "renders description below title" do
    render_inline(SectionComponent.new(title: "Account", description: "Manage your account")) { "Body" }

    assert_selector "h2", text: "Account"
    assert_selector "p.text-sm.text-stone-600", text: "Manage your account"
  end

  test "renders without title or description" do
    render_inline(SectionComponent.new) { "<p>Just content</p>".html_safe }

    assert_no_selector "h2"
    assert_no_selector "p.text-sm.text-stone-600"
    assert_text "Just content"
  end

  test "passes through extra classes" do
    render_inline(SectionComponent.new(class: "mt-6")) { "Body" }

    assert_selector "section.mt-6.rounded-xl"
  end

  test "passes through HTML options" do
    render_inline(SectionComponent.new(id: "reminder-section", aria: { labelledby: "heading" })) { "Body" }

    assert_selector "section#reminder-section[aria-labelledby='heading']"
  end
end
