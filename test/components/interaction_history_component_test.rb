require "test_helper"

class InteractionHistoryComponentTest < ViewComponent::TestCase
  test "renders the compact newest-first history and view-all link" do
    person = people(:ada)
    older = person.interactions.create!(occurred_on: 2.days.ago.to_date, note: "Older")
    newer = person.interactions.create!(
      occurred_on: 1.day.ago.to_date,
      contact_method_name: "Call",
      contact_method_icon_library: "material_icons",
      contact_method_icon_name: "call",
      note: "Newer"
    )

    rendered = render_inline InteractionHistoryComponent.new(person: person, interactions: [ newer, older ], total_count: 3)

    assert_selector "#interactions-history"
    assert_selector "#interactions-history-heading.text-lg.font-semibold", text: "Interactions"
    assert_selector "time[datetime='#{newer.occurred_on.iso8601}']", text: /#{Regexp.escape(I18n.l(newer.occurred_on, format: :long))}/
    assert_selector "li", text: /Newer/
    assert_selector "li", text: /Call/
    assert_selector "li span.material-icons", text: "call"
    path = Rails.application.routes.url_helpers.person_interactions_path(person)
    assert_selector "a[href='#{path}']", text: "View all (3)"
    assert_operator rendered.to_s.index("Newer"), :<, rendered.to_s.index("Older")
  end

  test "renders an empty state without a view-all link" do
    person = people(:ada)

    render_inline InteractionHistoryComponent.new(person: person, interactions: [], total_count: 0)

    assert_selector "#interactions-history", text: "No interactions recorded yet."
    assert_selector "#interactions-history.mt-8"
    assert_no_selector "a", text: /View all/
  end

  test "does not show view-all when the preview contains the full history" do
    person = people(:ada)
    interaction = person.interactions.create!(occurred_on: Date.current)

    render_inline InteractionHistoryComponent.new(person: person, interactions: [ interaction ], total_count: 1)

    assert_no_selector "a", text: /View all/
  end

  test "renders interactions without mutation controls when read-only" do
    person = people(:ada)
    interaction = person.interactions.create!(occurred_on: Date.current)

    render_inline InteractionHistoryComponent.new(
      person:, interactions: [ interaction ], total_count: 2, editable: false
    )

    assert_selector "time[datetime='#{interaction.occurred_on.iso8601}']"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.person_interactions_path(person)}']"
    assert_no_selector "a[href='#{Rails.application.routes.url_helpers.new_person_interaction_path(person)}']"
    assert_no_selector "a[href='#{Rails.application.routes.url_helpers.edit_person_interaction_path(person, interaction)}']"
    assert_no_selector "#delete-interaction-dialog"
  end
end
