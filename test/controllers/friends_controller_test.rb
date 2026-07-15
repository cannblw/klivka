require "test_helper"

class FriendsControllerTest < ActionDispatch::IntegrationTest
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
end
