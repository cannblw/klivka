require "test_helper"

class InteractionHistoryComponentTest < ViewComponent::TestCase
  test "renders the compact newest-first history and view-all link" do
    friend = friends(:ada)
    older = friend.interactions.create!(occurred_on: 2.days.ago.to_date, note: "Older")
    newer = friend.interactions.create!(occurred_on: 1.day.ago.to_date, contact_method: "call", note: "Newer")

    rendered = render_inline InteractionHistoryComponent.new(friend: friend, interactions: [ newer, older ], total_count: 3)

    assert_selector "#interactions-history"
    assert_selector "#interactions-history-heading.text-lg.font-semibold", text: "Interactions"
    assert_selector "time[datetime='#{newer.occurred_on.iso8601}']", text: /#{Regexp.escape(I18n.l(newer.occurred_on, format: :long))}/
    assert_selector "li", text: /Newer/
    assert_selector "li", text: /Call/
    path = Rails.application.routes.url_helpers.friend_interactions_path(friend)
    assert_selector "a[href='#{path}']", text: "View all (3)"
    assert_operator rendered.to_s.index("Newer"), :<, rendered.to_s.index("Older")
  end

  test "renders an empty state without a view-all link" do
    friend = friends(:ada)

    render_inline InteractionHistoryComponent.new(friend: friend, interactions: [], total_count: 0)

    assert_selector "#interactions-history", text: "No interactions recorded yet."
    assert_selector "#interactions-history.mt-8"
    assert_no_selector "a", text: /View all/
  end

  test "does not show view-all when the preview contains the full history" do
    friend = friends(:ada)
    interaction = friend.interactions.create!(occurred_on: Date.current)

    render_inline InteractionHistoryComponent.new(friend: friend, interactions: [ interaction ], total_count: 1)

    assert_no_selector "a", text: /View all/
  end
end
