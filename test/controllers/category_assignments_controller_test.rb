require "test_helper"

class CategoryAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "category assignment requires authentication" do
    sign_out

    patch person_category_assignment_url(people(:ada)), params: { category_assignment: { category_id: categories(:family).id } }

    assert_redirected_to new_session_url
  end

  test "category assignment moves a person into the user's category" do
    patch person_category_assignment_url(people(:ada)), params: { category_assignment: { category_id: categories(:family).id } }

    assert_redirected_to person_url(people(:ada))
    assert_equal categories(:family), people(:ada).reload.category
  end

  test "category assignment can return to the organizer" do
    patch person_category_assignment_url(people(:ada)), params: {
      category_assignment: { category_id: categories(:family).id, return_to: "categories" }
    }

    assert_redirected_to categories_url
    assert_equal categories(:family), people(:ada).reload.category
  end

  test "category assignment replaces the person's previous category" do
    people(:ada).update!(category: categories(:family))

    patch person_category_assignment_url(people(:ada)), params: {
      category_assignment: { category_id: categories(:friends).id }
    }

    assert_equal categories(:friends), people(:ada).reload.category
    assert_not_includes categories(:family).people.reload, people(:ada)
    assert_includes categories(:friends).people.reload, people(:ada)
  end

  test "category assignment returns a person to Uncategorized" do
    people(:ada).update!(category: categories(:family))

    patch person_category_assignment_url(people(:ada)), params: { category_assignment: { category_id: "" } }

    assert_redirected_to person_url(people(:ada))
    assert_nil people(:ada).reload.category
  end

  test "category assignment cannot use another user's category" do
    patch person_category_assignment_url(people(:ada)), params: {
      category_assignment: { category_id: categories(:family_for_user_two).id }
    }

    assert_response :not_found
    assert_nil people(:ada).reload.category
  end

  test "category assignment cannot change another user's person" do
    patch person_category_assignment_url(people(:bob)), params: {
      category_assignment: { category_id: categories(:family).id }
    }

    assert_response :not_found
    assert_nil people(:bob).reload.category
  end

  test "category assignment cannot change an archived person" do
    people(:ada).archive!

    patch person_category_assignment_url(people(:ada)), params: {
      category_assignment: { category_id: categories(:family).id }
    }

    assert_response :not_found
    assert_nil people(:ada).reload.category
  end
end
