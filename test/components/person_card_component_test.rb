require "test_helper"

class PersonCardComponentTest < ViewComponent::TestCase
  test "renders name and initials" do
    person = Person.create!(name: "Ada Lovelace", user: users(:one))
    render_inline PersonCardComponent.new(person: person)

    assert_text "Ada Lovelace"
    assert_text "AL"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.person_path(person)}'][data-turbo-frame='_top']"
  end

  test "single-word names get a single initial" do
    render_inline PersonCardComponent.new(person: Person.create!(name: "Ada", user: users(:one)))

    assert_text "A"
  end

  test "optionally renders the person's category" do
    person = Person.create!(name: "Ada Lovelace", user: users(:one), category: categories(:family))

    render_inline PersonCardComponent.new(person: person, show_category: true)

    assert_text categories(:family).name
  end

  test "omits the category when the surrounding view already provides it" do
    person = Person.create!(name: "Ada Lovelace", user: users(:one), category: categories(:family))

    render_inline PersonCardComponent.new(person: person)

    assert_no_text categories(:family).name
  end

  test "marks an archived person without changing the profile link" do
    person = Person.create!(name: "Ada Lovelace", user: users(:one), archived_at: Time.current)

    render_inline PersonCardComponent.new(person:)

    assert_selector "[data-archived-person]", text: "Archived"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.person_path(person)}']"
  end
end
