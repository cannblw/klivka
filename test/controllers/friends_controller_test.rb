require "test_helper"

class FriendsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get root_url

    assert_redirected_to new_session_url
  end

  test "index is the root page and lists friends" do
    get root_url

    assert_response :success
    assert_select "h1", "Friends"
    assert_select "main", /Ada Lovelace/
    assert_select "main", /Grace Hopper/
  end

  test "index shows an empty state when there are no friends" do
    Friend.destroy_all

    get root_url

    assert_response :success
    assert_select "main", /No friends yet/
  end

  test "create adds a friend and redirects to their page" do
    assert_difference "Friend.count", 1 do
      post friends_url, params: { friend: { name: "Marie Curie" } }
    end

    assert_redirected_to friend_url(Friend.find_by!(name: "Marie Curie"))
    follow_redirect!
    assert_select "h1", "Marie Curie"
  end

  test "create with a blank name saves nothing and shows the error" do
    assert_no_difference "Friend.count" do
      post friends_url, params: { friend: { name: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /can't be blank/
  end

  test "index only lists the current user's friends" do
    get root_url

    assert_response :success
    assert_select "main", /Ada Lovelace/
    assert_select "main", { text: /Bob Ross/, count: 0 }
  end

  test "show returns 404 for another user's friend" do
    get friend_url(friends(:bob))

    assert_response :not_found
  end

  test "created friends belong to the current user" do
    post friends_url, params: { friend: { name: "Marie Curie" } }

    assert_equal users(:one), Friend.find_by!(name: "Marie Curie").user
  end

  test "show displays the friend" do
    get friend_url(friends(:ada))

    assert_response :success
    assert_select "h1", "Ada Lovelace"
  end
end
