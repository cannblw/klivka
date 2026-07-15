require "test_helper"

class FriendCardComponentTest < ViewComponent::TestCase
  test "renders name and initials" do
    friend = Friend.create!(name: "Ada Lovelace")
    render_inline FriendCardComponent.new(friend: friend)

    assert_text "Ada Lovelace"
    assert_text "AL"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.friend_path(friend)}']"
  end

  test "single-word names get a single initial" do
    render_inline FriendCardComponent.new(friend: Friend.create!(name: "Ada"))

    assert_text "A"
  end
end
