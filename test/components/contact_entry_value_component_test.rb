require "test_helper"

class ContactEntryValueComponentTest < ViewComponent::TestCase
  test "renders a callable phone number with its copy action" do
    entry = entries(:phone)

    render_inline ContactEntryValueComponent.new(entry:)

    assert_selector "a[href='tel:555-1234']", text: "555-1234"
    assert_selector "button.size-6[data-controller='clipboard'][data-clipboard-text-value='555-1234'][aria-label]"
    assert_selector ".material-icons[aria-hidden='true']", text: "content_copy"
  end

  test "renders an email link with its optional label" do
    entry = entries(:email)

    render_inline ContactEntryValueComponent.new(entry:)

    assert_selector "a[href='mailto:ada@example.com']", text: "ada@example.com"
    assert_selector "button[data-clipboard-text-value='ada@example.com'][aria-label]"
    assert_selector ".rounded-full", text: "Work"
  end

  test "renders nothing when the contact value is absent" do
    entry = Entry::Phone.new(person: people(:ada), content: { "label" => "Home" })

    render_inline ContactEntryValueComponent.new(entry:)

    assert_no_selector "a, button, .rounded-full"
  end

  test "rejects entries without contact behavior" do
    error = assert_raises(ArgumentError) do
      ContactEntryValueComponent.new(entry: entries(:ada_birthday))
    end

    assert_match(/Entry::Birthday/, error.message)
  end
end
