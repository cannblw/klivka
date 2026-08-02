require "test_helper"

class FriendCardComponentTest < ViewComponent::TestCase
  test "renders name and initials" do
    friend = Friend.create!(name: "Ada Lovelace", user: users(:one))
    render_inline FriendCardComponent.new(friend: friend)

    assert_text "Ada Lovelace"
    assert_text "AL"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.friend_path(friend)}'][data-turbo-frame='_top']"
  end

  test "single-word names get a single initial" do
    render_inline FriendCardComponent.new(friend: Friend.create!(name: "Ada", user: users(:one)))

    assert_text "A"
  end
end
