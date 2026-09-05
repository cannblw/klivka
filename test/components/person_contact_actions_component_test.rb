require "test_helper"

class PersonContactActionsComponentTest < ViewComponent::TestCase
  test "renders no actions without usable phone or email entries" do
    entries = [
      Entry::Phone.new(content: { number: "" }),
      Entry::Email.new(content: { email: "" })
    ]

    render_inline(PersonContactActionsComponent.new(entries: entries))

    assert_selector "turbo-frame#person_contact_actions"
    assert_no_selector "#contact-actions-heading"
  end

  test "renders up to two actions per type and puts every value in the dialog" do
    entries = [
      Entry::Phone.new(content: { number: "555-1000", label: "Mobile" }),
      Entry::Phone.new(content: { number: "555-2000" }),
      Entry::Phone.new(content: { number: "555-3000" }),
      Entry::Email.new(content: { email: "one@example.com", label: "Work" }),
      Entry::Email.new(content: { email: "two@example.com" }),
      Entry::Email.new(content: { email: "three@example.com" })
    ]

    render_inline(PersonContactActionsComponent.new(entries: entries))

    assert_selector "#contact-actions-heading", text: "Contact actions"
    assert_selector "#contact-actions-heading.text-lg.font-semibold"
    assert_selector "[data-controller='dialog'].mt-8"
    assert_selector "[aria-labelledby='contact-actions-heading'] a[href^='tel:']", count: 2
    assert_selector "[aria-labelledby='contact-actions-heading'] a[href^='mailto:']", count: 2
    assert_selector "[aria-label='Call 555-1000'] .text-xs", text: "Mobile"
    assert_selector "[aria-label='Call 555-1000'] .break-all", text: "555-1000"
    assert_selector "[aria-label='Call 555-1000'] .material-icons", text: "call"
    assert_selector "[aria-label='Email one@example.com'] .text-xs", text: "Work"
    assert_selector "[aria-label='Email one@example.com'] .break-all", text: "one@example.com"
    assert_selector "[aria-label='Email one@example.com'] .material-icons", text: "email"
    assert_selector "button[data-action='dialog#open']", text: "View all contact methods (6)"
    assert_selector "dialog a[href^='tel:']", count: 3
    assert_selector "dialog a[href^='mailto:']", count: 3
    assert_selector "dialog button.size-6 .material-icons[aria-hidden='true']", count: 6
    assert_selector "dialog .max-h-\\[70vh\\].overflow-y-auto"
  end

  test "omits the dialog when both contact types fit in the quick actions" do
    entries = [
      Entry::Phone.new(content: { number: "555-1000" }),
      Entry::Email.new(content: { email: "one@example.com" })
    ]

    render_inline(PersonContactActionsComponent.new(entries: entries))

    assert_no_selector "dialog"
    assert_no_selector "button[data-action='dialog#open']"
  end
end
