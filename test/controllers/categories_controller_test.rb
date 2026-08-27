require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "categories require authentication" do
    sign_out

    get categories_url

    assert_redirected_to new_session_url
  end

  test "index shows only the current user's categories and person counts" do
    people(:ada).update!(category: categories(:family))

    get categories_url

    assert_response :success
    assert_select "h1"
    assert_select "header a[href='#{categories_path}']"
    assert_select "turbo-frame#category_organizer"
    assert_select "section[aria-labelledby='category-#{categories(:family).id}-heading'] [data-person-count='1']"
    assert_select "section[aria-labelledby='category-#{categories(:family_for_user_two).id}-heading']", count: 0
    assert_select "form[action='#{categories_path}'] input[name='category[name]']"
  end

  test "person suggestions reuse person search and identify current categories" do
    people(:grace).update!(category: categories(:people))

    get person_suggestions_categories_url, params: { category_id: categories(:family).id, query: "grac" }

    assert_response :success
    suggestion = response.parsed_body.sole
    assert_equal people(:grace).name, suggestion.fetch("name")
    assert_equal categories(:people).name, suggestion.fetch("category")
    assert_equal person_category_assignment_path(people(:grace)), suggestion.fetch("assignment_url")
  end

  test "person suggestions exclude people already in the destination category" do
    people(:ada).update!(category: categories(:family))

    get person_suggestions_categories_url, params: { category_id: categories(:family).id, query: "ada" }

    assert_response :success
    assert_empty response.parsed_body
  end

  test "person suggestions require a query" do
    get person_suggestions_categories_url, params: { category_id: categories(:family).id }

    assert_response :success
    assert_empty response.parsed_body
  end

  test "person suggestions cannot use another user's category" do
    get person_suggestions_categories_url, params: { category_id: categories(:family_for_user_two).id, query: "ada" }

    assert_response :not_found
  end

  test "create adds a category for the current user" do
    assert_difference -> { users(:one).categories.count }, 1 do
      post categories_url, params: { category: { name: "Neighbors" } }
    end

    assert_redirected_to categories_url
    assert_equal "Neighbors", users(:one).categories.find_by!(normalized_name: "neighbors").name
  end

  test "create shows validation errors without adding a category" do
    assert_no_difference "Category.count" do
      post categories_url, params: { category: { name: " FAMILY " } }
    end

    assert_response :unprocessable_entity
    assert_select "form[action='#{categories_path}'] input[name='category[name]']"
    assert_select "form[action='#{categories_path}'] .text-red-600"
  end

  test "update renames a category owned by the current user" do
    patch category_url(categories(:family)), params: { category: { name: "Close family" } }

    assert_redirected_to categories_url
    assert_equal "Close family", categories(:family).reload.name
    assert_equal "close family", categories(:family).normalized_name
  end

  test "update shows validation errors in the category rename form" do
    patch category_url(categories(:family)), params: { category: { name: "People" } }

    assert_response :unprocessable_entity
    assert_select "form[action='#{category_path(categories(:family))}'] input[name='category[name]']"
    assert_select "form[action='#{category_path(categories(:family))}'] .text-red-600"
  end

  test "update cannot rename another user's category" do
    patch category_url(categories(:family_for_user_two)), params: { category: { name: "Changed" } }

    assert_response :not_found
    assert_equal "Family", categories(:family_for_user_two).reload.name
  end

  test "destroy deletes the category and leaves its people uncategorized" do
    person = people(:ada)
    person.update!(category: categories(:family))

    assert_difference "Category.count", -1 do
      assert_no_difference "Person.count" do
        delete category_url(categories(:family))
      end
    end

    assert_redirected_to categories_url
    assert_nil person.reload.category
  end

  test "destroy cannot delete another user's category" do
    assert_no_difference "Category.count" do
      delete category_url(categories(:family_for_user_two))
    end

    assert_response :not_found
  end
end
