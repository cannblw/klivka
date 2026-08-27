require "test_helper"

class PersonSuggestionsComponentTest < ViewComponent::TestCase
  test "offers optional ideas that have not been added" do
    person = people(:ada)

    rendered_component = render_inline(PersonSuggestionsComponent.new(person: person, entries: person.entries.ordered.to_a))

    assert_selector "section.mt-8 h2.text-base.font-semibold", text: "Ideas, if useful"
    assert_selector "p", text: "Add these whenever they come to mind."

    suggestion_links = rendered_component.css("a").index_by { |link| link.css("span").last.text.strip }
    {
      "How you met" => "Entry::FirstMet",
      "A date" => "Entry::Date",
      "Gift ideas" => "Entry::GiftList"
    }.each do |label, type|
      expected_path = Rails.application.routes.url_helpers.new_person_entry_path(person, type: type)
      assert_equal expected_path, suggestion_links.fetch(label)["href"]
    end
  end

  test "hides ideas that already have an entry" do
    person = people(:ada)
    Entry::FirstMet.create!(person: person, entry_date: Date.new(1835, 1, 1), content: { "date_precision" => "year" })
    Entry::Date.create!(person: person, entry_date: Date.new(1835, 12, 10), content: { "label" => "A date" })
    Entry::GiftList.create!(person: person, items: [ { "text" => "A gift" } ])

    render_inline(PersonSuggestionsComponent.new(person: person, entries: person.entries.ordered.to_a))

    assert_selector "#person-suggestions-heading", count: 0
  end
end
