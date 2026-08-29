require "test_helper"

class PersonCategoryComponentTest < ViewComponent::TestCase
  test "person category renders the current optional assignment" do
    person = people(:ada)
    person.update!(category: categories(:family))
    path = Rails.application.routes.url_helpers.person_category_assignment_path(person)

    render_inline PersonCategoryComponent.new(person: person, categories: users(:one).categories.order(:name))

    assert_selector "[data-controller='toggle'] [data-toggle-target='content']:not(.hidden)"
    assert_selector "button[aria-label] .material-icons[aria-hidden='true']", text: "edit"
    assert_selector "form[action='#{path}']", visible: :all
    assert_selector "select[name='category_assignment[category_id]'] option[selected][value='#{categories(:family).id}']"
    assert_selector "select[name='category_assignment[category_id]'] option[value='']"
    assert_link "Create or manage categories", href: Rails.application.routes.url_helpers.categories_path
  end

  test "person without available categories can reach category creation" do
    person = users(:one).people.create!(name: "No category yet")

    render_inline PersonCategoryComponent.new(person:, categories: [])

    assert_selector "select[name='category_assignment[category_id]'] option", count: 1
    assert_link "Create or manage categories", href: Rails.application.routes.url_helpers.categories_path
  end
end
