require "test_helper"

class InteractionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out

    post contacted_today_friend_interactions_url(friends(:ada)), params: { occurred_at: Time.current.iso8601 }

    assert_redirected_to new_session_url
  end

  test "creates an interaction with optional details" do
    occurred_at = 1.hour.ago.change(usec: 0)

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        interaction: {
          occurred_at: occurred_at.iso8601,
          contact_method: "in_person",
          note: "Met at the market"
        }
      }
    end

    assert_redirected_to friend_url(friends(:ada))
    interaction = friends(:ada).interactions.last
    assert_equal occurred_at, interaction.occurred_at
    assert_equal "in_person", interaction.contact_method
    assert_equal "Met at the market", interaction.note
  end

  test "updates an interaction" do
    interaction = friends(:ada).interactions.create!(occurred_at: 1.day.ago)

    patch friend_interaction_url(friends(:ada), interaction), params: {
      interaction: { contact_method: "message", note: "Caught up" }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal "message", interaction.reload.contact_method
    assert_equal "Caught up", interaction.note
  end

  test "destroys an interaction" do
    interaction = friends(:ada).interactions.create!(occurred_at: 1.day.ago)

    assert_difference -> { friends(:ada).interactions.count }, -1 do
      delete friend_interaction_url(friends(:ada), interaction)
    end

    assert_redirected_to friend_url(friends(:ada))
  end

  test "contacted today stores the browser timestamp" do
    occurred_at = 30.minutes.ago.change(usec: 0)

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post contacted_today_friend_interactions_url(friends(:ada)), params: { occurred_at: occurred_at.iso8601 }
    end

    assert_redirected_to friend_url(friends(:ada))
    assert_equal occurred_at, friends(:ada).interactions.recent.first.occurred_at
    assert_equal "Interaction recorded.", flash[:notice]
  end

  test "contacted today falls back to server time when the browser timestamp is missing" do
    before_request = Time.current

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post contacted_today_friend_interactions_url(friends(:ada))
    end

    assert_redirected_to friend_url(friends(:ada))
    interaction = friends(:ada).interactions.recent.first
    assert_operator interaction.occurred_at, :>=, before_request
    assert_equal "Interaction recorded using server time. Check that JavaScript is enabled if the time looks wrong.", flash[:notice]
  end

  test "contacted today falls back when the browser timestamp is invalid or future" do
    [ "not-a-timestamp", 1.hour.from_now.iso8601 ].each do |occurred_at|
      assert_difference -> { friends(:ada).interactions.count }, 1 do
        post contacted_today_friend_interactions_url(friends(:ada)), params: { occurred_at: occurred_at }
      end

      assert_redirected_to friend_url(friends(:ada))
      assert_equal "Interaction recorded using server time. Check that JavaScript is enabled if the time looks wrong.", flash[:notice]
    end
  end

  test "does not access another user's friend or interaction" do
    interaction = friends(:ada).interactions.create!(occurred_at: 1.day.ago)

    get friend_interactions_url(friends(:bob))
    assert_response :not_found

    patch friend_interaction_url(friends(:bob), interaction), params: { interaction: { note: "Nope" } }
    assert_response :not_found

    delete friend_interaction_url(friends(:bob), interaction)
    assert_response :not_found
  end
end
