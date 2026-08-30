require "test_helper"

class PersonAvatarComponentTest < ViewComponent::TestCase
  test "shows the person's initials as a decorative fallback" do
    person = Person.create!(name: "Ada Lovelace", user: users(:one))

    render_inline PersonAvatarComponent.new(person:)

    assert_selector "[aria-hidden='true']", text: "AL"
  end
end
