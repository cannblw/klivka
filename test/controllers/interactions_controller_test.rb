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

  test "logging contact clears an active reminder snooze" do
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: 1.week.ago.to_date,
      snoozed_until: 1.week.from_now.to_date
    )
    previous_lock_version = setting.lock_version

    post friend_interactions_url(friends(:ada)), params: {
      interaction: { occurred_on: Date.current.iso8601 }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_nil setting.reload.snoozed_until
    assert_operator setting.lock_version, :>, previous_lock_version
  end

  test "logging an interaction from before the contact reminder was enabled keeps its snooze" do
    enabled_on = Date.current
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: enabled_on,
      snoozed_until: 1.week.from_now.to_date
    )

    post friend_interactions_url(friends(:ada)), params: {
      interaction: { occurred_on: enabled_on.yesterday.iso8601 }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal 1.week.from_now.to_date, setting.reload.snoozed_until
  end

  test "an invalid interaction leaves an active reminder snooze unchanged" do
    snoozed_until = 1.week.from_now.to_date
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: 1.week.ago.to_date,
      snoozed_until: snoozed_until
    )

    post friend_interactions_url(friends(:ada)), params: {
      interaction: { occurred_on: Date.tomorrow.iso8601 }
    }

    assert_response :unprocessable_entity
    assert_equal snoozed_until, setting.reload.snoozed_until
  end

  test "editing interaction details keeps an active reminder snooze" do
    interaction = friends(:ada).interactions.create!(occurred_on: Date.current)
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: 1.week.ago.to_date,
      snoozed_until: 1.week.from_now.to_date
    )

    patch friend_interaction_url(friends(:ada), interaction), params: {
      interaction: { note: "Caught up" }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_equal 1.week.from_now.to_date, setting.reload.snoozed_until
  end

  test "changing an interaction date to today clears an active reminder snooze" do
    interaction = friends(:ada).interactions.create!(occurred_on: 2.weeks.ago.to_date)
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: 1.week.ago.to_date,
      snoozed_until: 1.week.from_now.to_date
    )

    patch friend_interaction_url(friends(:ada), interaction), params: {
      interaction: { occurred_on: Date.current.iso8601 }
    }

    assert_redirected_to friend_url(friends(:ada))
    assert_nil setting.reload.snoozed_until
  end

  test "a contact makes a previously opened snooze request stale" do
    setting = friends(:ada).create_keep_in_touch_setting!(
      cadence: "weekly",
      enabled_on: 1.week.ago.to_date,
      snoozed_until: 1.week.from_now.to_date
    )
    stale_lock_version = setting.lock_version

    post friend_interactions_url(friends(:ada)), params: {
      interaction: { occurred_on: Date.current.iso8601 }
    }

    patch snooze_friend_keep_in_touch_setting_url(friends(:ada)), params: {
      keep_in_touch_setting: { lock_version: stale_lock_version }
    }

    assert_nil setting.reload.snoozed_until
    assert_equal "This contact reminder changed. Please review the latest details.", flash[:alert]
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
        interaction: { occurred_on: occurred_on.iso8601 }
      }
    end

    assert_redirected_to friend_url(friends(:ada))
    assert_equal occurred_on, friends(:ada).interactions.recent.first.occurred_on
    assert_equal "Interaction recorded.", flash[:notice]
  end

  test "quick log rejects an interaction after the user's current date" do
    user = users(:one)
    user.update!(time_zone: "America/Los_Angeles")
    sign_out
    sign_in_as user

    travel_to Time.utc(2026, 8, 10, 0, 30) do
      assert_no_difference -> { friends(:ada).interactions.count } do
        post friend_interactions_url(friends(:ada)), params: {
          context: "quick_log",
          interaction: { occurred_on: Date.new(2026, 8, 10).iso8601 }
        }
      end
    end

    assert_response :unprocessable_entity
  end

  test "invalid quick log reopens the unsaved modal with errors and submitted details" do
    assert_no_difference -> { friends(:ada).interactions.count } do
      post friend_interactions_url(friends(:ada)), params: {
        context: "quick_log",
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

  test "index shows 25 newest interactions and next-page navigation" do
    27.times do |index|
      friends(:ada).interactions.create!(occurred_on: (index + 1).days.ago.to_date, note: "Interaction #{index + 1}")
    end

    get friend_interactions_url(friends(:ada))

    assert_response :success
    assert_select "#interactions-history li", count: 25
    assert_select "#interactions-history li", text: /Interaction 1/
    assert_select "#interactions-history li", text: /Interaction 25/
    assert_select "#interactions-history li", text: /Interaction 26/, count: 0
    assert_select "a", text: "Next"
    assert_select "nav", text: /Page 1/
  end

  test "index shows the previous page and remaining interactions" do
    27.times do |index|
      friends(:ada).interactions.create!(occurred_on: (index + 1).days.ago.to_date, note: "Interaction #{index + 1}")
    end

    get friend_interactions_url(friends(:ada), page: 2)

    assert_response :success
    assert_select "#interactions-history li", count: 2
    assert_select "#interactions-history li", text: /Interaction 26/
    assert_select "#interactions-history li", text: /Interaction 27/
    assert_select "a", text: "Previous"
    assert_select "a", text: "Next", count: 0
  end

  test "index treats invalid pages as the first page" do
    26.times do |index|
      friends(:ada).interactions.create!(occurred_on: (index + 1).days.ago.to_date)
    end

    get friend_interactions_url(friends(:ada), page: "not-a-number")

    assert_response :success
    assert_select "nav", text: /Page 1/
  end
end
