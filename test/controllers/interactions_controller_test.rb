require "test_helper"

class InteractionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out

    post friend_interactions_url(friends(:ada)), params: {
      interaction: { occurred_on: Date.current.iso8601 }
    }

    assert_redirected_to new_session_url
  end

  test "creates an interaction with optional details" do
    occurred_on = 1.day.ago.to_date

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        interaction: {
          occurred_on: occurred_on.iso8601,
          contact_method: "in_person",
          note: "Met at the market"
        }
      }
    end

    assert_redirected_to friend_url(friends(:ada))
    interaction = friends(:ada).interactions.last
    assert_equal occurred_on, interaction.occurred_on
    assert_equal "in_person", interaction.contact_method
    assert_equal "Met at the market", interaction.note
  end

  test "updates an interaction" do
    interaction = friends(:ada).interactions.create!(occurred_on: 1.day.ago.to_date)

    patch friend_interaction_url(friends(:ada), interaction), params: {
      interaction: { contact_method: "message", note: "Caught up" }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal "message", interaction.reload.contact_method
    assert_equal "Caught up", interaction.note
  end

  test "destroys an interaction" do
    interaction = friends(:ada).interactions.create!(occurred_on: 1.day.ago.to_date)

    assert_difference -> { friends(:ada).interactions.count }, -1 do
      delete friend_interaction_url(friends(:ada), interaction)
    end

    assert_redirected_to friend_url(friends(:ada))
  end

  test "quick log creates an interaction only when the form is saved" do
    occurred_on = 1.day.ago.to_date

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
        date_source: "browser",
        browser_date: Date.current.iso8601,
        interaction: { occurred_on: occurred_on.iso8601 }
      }
    end

    assert_redirected_to friend_url(friends(:ada))
    assert_equal occurred_on, friends(:ada).interactions.recent.first.occurred_on
    assert_equal "Interaction recorded.", flash[:notice]
  end

  test "quick log accepts the browser's local date when it is ahead of the server" do
    browser_date = Date.tomorrow

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
        date_source: "browser",
        browser_date: browser_date.iso8601,
        interaction: { occurred_on: browser_date.iso8601 }
      }
    end

    assert_equal browser_date, friends(:ada).interactions.recent.first.occurred_on
  end

  test "quick log warns when it saves the server date fallback" do
    server_date = Date.current

    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
        date_source: "server",
        interaction: { occurred_on: 1.day.ago.to_date.iso8601 }
      }
    end

    assert_redirected_to friend_url(friends(:ada))
    assert_equal server_date, friends(:ada).interactions.recent.first.occurred_on
    assert_equal "Interaction recorded using the server date. Check that JavaScript is enabled if the date looks wrong.", flash[:notice]
  end

  test "quick log falls back when the browser date is malformed" do
    assert_difference -> { friends(:ada).interactions.count }, 1 do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
        date_source: "browser",
        browser_date: "not-a-date",
        interaction: { occurred_on: 1.day.ago.to_date.iso8601 }
      }
    end

    assert_equal Date.current, friends(:ada).interactions.recent.first.occurred_on
    assert_equal "Interaction recorded using the server date. Check that JavaScript is enabled if the date looks wrong.", flash[:notice]
  end

  test "invalid quick log reopens the unsaved modal with errors and submitted details" do
    assert_no_difference -> { friends(:ada).interactions.count } do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
        date_source: "browser",
        browser_date: Date.current.iso8601,
        interaction: { occurred_on: Date.tomorrow.iso8601, contact_method: "call", note: "Keep this note" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[data-controller~='dialog'][data-dialog-open-value='true'] dialog##{QuickInteractionComponent::DOM_ID}"
    assert_select "textarea", text: "Keep this note"
    assert_select ".text-red-600", text: /must not be in the future/
  end

  test "does not access another user's friend or interaction" do
    interaction = friends(:ada).interactions.create!(occurred_on: 1.day.ago.to_date)

    get friend_interactions_url(friends(:bob))
    assert_response :not_found

    patch friend_interaction_url(friends(:bob), interaction), params: { interaction: { note: "Nope" } }
    assert_response :not_found

    delete friend_interaction_url(friends(:bob), interaction)
    assert_response :not_found
  end
end
