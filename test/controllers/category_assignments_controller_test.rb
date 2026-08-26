require "test_helper"

class CategoryAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "category assignment requires authentication" do
    sign_out

    patch friend_category_assignment_url(friends(:ada)), params: { category_assignment: { category_id: categories(:family).id } }

    assert_redirected_to new_session_url
  end

  test "category assignment moves a friend into the user's category" do
    patch friend_category_assignment_url(friends(:ada)), params: { category_assignment: { category_id: categories(:family).id } }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal categories(:family), friends(:ada).reload.category
  end

  test "category assignment can return to the organizer" do
    patch friend_category_assignment_url(friends(:ada)), params: {
      category_assignment: { category_id: categories(:family).id, return_to: "categories" }
    }

    assert_redirected_to categories_url
    assert_equal categories(:family), friends(:ada).reload.category
  end

  test "category assignment replaces the friend's previous category" do
    friends(:ada).update!(category: categories(:family))

    patch friend_category_assignment_url(friends(:ada)), params: {
      category_assignment: { category_id: categories(:friends).id }
    }

    assert_equal categories(:friends), friends(:ada).reload.category
    assert_not_includes categories(:family).friends.reload, friends(:ada)
    assert_includes categories(:friends).friends.reload, friends(:ada)
  end

  test "category assignment returns a friend to Uncategorized" do
    friends(:ada).update!(category: categories(:family))

    patch friend_category_assignment_url(friends(:ada)), params: { category_assignment: { category_id: "" } }

    assert_redirected_to friend_url(friends(:ada))
    assert_nil friends(:ada).reload.category
  end

  test "category assignment cannot use another user's category" do
    patch friend_category_assignment_url(friends(:ada)), params: {
      category_assignment: { category_id: categories(:family_for_user_two).id }
    }

    assert_response :not_found
    assert_nil friends(:ada).reload.category
  end

  test "category assignment cannot change another user's friend" do
    patch friend_category_assignment_url(friends(:bob)), params: {
      category_assignment: { category_id: categories(:family).id }
    }

    assert_response :not_found
    assert_nil friends(:bob).reload.category
  end
end
