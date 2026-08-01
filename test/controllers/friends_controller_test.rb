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
    assert_select "form[data-controller='search'][data-turbo-frame='friends_grid']"
    assert_select "form[data-search-delay-value='#{Rails.application.config.x.friend_search_debounce_milliseconds}']"
    assert_select "input[type='search'][name='query']"
    assert_select "turbo-frame#friends_grid"
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
    assert_select "input[type='search'][value='ada']"
    assert_select "main", /Ada Lovelace/
    assert_select "main", { text: /Bob Ross/, count: 0 }
  end

  test "index searches the current user's friends" do
    get root_url, params: { query: "ada" }

    assert_response :success
    assert_select "main", /Ada Lovelace/
    assert_select "main", { text: /Grace Hopper/, count: 0 }
  end

  test "index does not return another user's friend in search results" do
    get root_url, params: { query: "bob" }

    assert_response :success
    assert_select "main", { text: /Bob Ross/, count: 0 }
  end

  test "index returns no friends for a query with no matches" do
    get root_url, params: { query: "zzzz" }

    assert_response :success
    assert_select "main", /No friends matching 'zzzz'/
    assert_select "main", { text: /Ada Lovelace/, count: 0 }
    assert_select "main", { text: /Grace Hopper/, count: 0 }
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
    assert_select "h1", /Ada Lovelace/
  end

  test "update renames the friend" do
    patch friend_url(friends(:ada)), params: { friend: { name: "Ada King" } }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal "Ada King", friends(:ada).reload.name
  end

  test "update with blank name re-renders with error" do
    patch friend_url(friends(:ada)), params: { friend: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "main", /can't be blank/
  end

  test "destroy removes the friend and redirects to root" do
    assert_difference "Friend.count", -1 do
      delete friend_url(friends(:ada))
    end

    assert_redirected_to root_url
  end

  test "cross-user returns 404 for update" do
    patch friend_url(friends(:bob)), params: { friend: { name: "Nope" } }

    assert_response :not_found
  end

  test "cross-user returns 404 for destroy" do
    delete friend_url(friends(:bob))

    assert_response :not_found
  end
end
