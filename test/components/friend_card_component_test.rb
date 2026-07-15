require "test_helper"

class FriendCardComponentTest < ViewComponent::TestCase
  test "renders name and initials" do
    render_inline FriendCardComponent.new(friend: Friend.new(name: "Ada Lovelace"))

    assert_text "Ada Lovelace"
    assert_text "AL"
  end

  test "single-word names get a single initial" do
    render_inline FriendCardComponent.new(friend: Friend.new(name: "Ada"))

    assert_text "A"
  end
end
