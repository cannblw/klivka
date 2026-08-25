require "test_helper"

class FriendSuggestionsComponentTest < ViewComponent::TestCase
  test "offers optional ideas that have not been added" do
    friend = friends(:ada)

    rendered_component = render_inline(FriendSuggestionsComponent.new(friend: friend, entries: friend.entries.ordered.to_a))

    assert_selector "section.mt-8 h2.text-base.font-semibold", text: "Ideas, if useful"
    assert_selector "p", text: "Add these whenever they come to mind."

    suggestion_links = rendered_component.css("a").index_by { |link| link.css("span").last.text.strip }
    {
      "How you met" => "Entry::FirstMet",
      "A date" => "Entry::Date",
      "Gift ideas" => "Entry::GiftList"
    }.each do |label, type|
      expected_path = Rails.application.routes.url_helpers.new_friend_entry_path(friend, type: type)
      assert_equal expected_path, suggestion_links.fetch(label)["href"]
    end
  end

  test "hides ideas that already have an entry" do
    friend = friends(:ada)
    Entry::FirstMet.create!(friend: friend, entry_date: Date.new(1835, 1, 1), content: { "date_precision" => "year" })
    Entry::Date.create!(friend: friend, entry_date: Date.new(1835, 12, 10), content: { "label" => "A date" })
    Entry::GiftList.create!(friend: friend, items: [ { "text" => "A gift" } ])

    render_inline(FriendSuggestionsComponent.new(friend: friend, entries: friend.entries.ordered.to_a))

    assert_selector "#friend-suggestions-heading", count: 0
  end
end
