require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    get root_url

    assert_redirected_to new_session_url
  end

  test "old friend URLs are not part of the people routing contract" do
    get "/friends"

    assert_response :not_found
  end

  test "index is the root page and lists people" do
    get root_url

    assert_response :success
    assert_select "h1", "People"
    assert_select "form[data-controller='search'][data-action='formdata->search#prepareFormData'][data-turbo-frame='people_grid']"
    assert_select "form[data-turbo-action='advance']"
    assert_select "form[data-search-delay-value='#{Rails.application.config.x.person_search_debounce_milliseconds}']"
    assert_select "input[type='search'][name='query']"
    assert_select "select[name='sort']"
    assert_select "select[name='sort'] option", count: 3
    assert_select "header a[href='#{categories_path}']"
    assert_select "turbo-frame#people_grid"
    assert_select "main", /Ada Lovelace/
    assert_select "main", /Grace Hopper/
    assert_select "nav[aria-label='Person view']", count: 0
    assert_select "#uncategorized-people-heading", count: 0
  end

  test "index groups people after the first category assignment" do
    people(:ada).update!(category: categories(:family))

    get root_url

    assert_response :success
    assert_select "nav[aria-label='Person view'] a[aria-current='true'][href='#{root_path}']"
    assert_select "section[aria-labelledby='person-category-#{categories(:family).id}-heading']" do
      assert_select "h2", text: categories(:family).name
      assert_select "a", text: /Ada Lovelace/
      assert_select "a", { text: /Grace Hopper/, count: 0 }
    end
    assert_select "section[aria-labelledby='person-category-#{categories(:people).id}-heading']", count: 0
    assert_select "section[aria-labelledby='uncategorized-people-heading']" do
      assert_select "a", text: /Grace Hopper/
    end
  end

  test "grouped view applies the selected sort within each category" do
    people(:ada).update!(category: categories(:family), updated_at: 2.days.ago)
    people(:grace).update!(category: categories(:family), updated_at: 1.day.ago)

    get root_url, params: { sort: "recently_updated" }

    names = css_select("section[aria-labelledby='person-category-#{categories(:family).id}-heading'] a p.font-medium").map { |node| node.text.strip }
    assert_equal [ "Grace Hopper", "Ada Lovelace" ], names
    assert_select "a[href='#{root_path(sort: "recently_updated", view: "all")}']"
  end

  test "grouped view omits Uncategorized when every person has a category" do
    people(:ada).update!(category: categories(:family))
    people(:grace).update!(category: categories(:people))

    get root_url

    assert_response :success
    assert_select "#uncategorized-people-heading", count: 0
  end

  test "all people view stays flat and shows category context" do
    people(:ada).update!(category: categories(:family))

    get root_url, params: { view: "all" }

    assert_response :success
    assert_select "input[type='hidden'][name='view'][value='all']"
    assert_select "nav[aria-label='Person view'] a[aria-current='true'][href='#{root_path(view: "all")}']"
    assert_select "section[aria-labelledby^='person-category-']", count: 0
    assert_select "a[href='#{person_path(people(:ada))}']", text: /#{categories(:family).name}/
  end

  test "invalid person view defaults to grouped" do
    people(:ada).update!(category: categories(:family))

    get root_url, params: { view: "columns" }

    assert_response :success
    assert_select "section[aria-labelledby='person-category-#{categories(:family).id}-heading']"
    assert_select "input[type='hidden'][name='view']", count: 0
  end

  test "search results stay flat and preserve the selected person view" do
    people(:ada).update!(category: categories(:family))

    get root_url, params: { query: "ada", view: "all" }

    assert_response :success
    assert_select "input[type='hidden'][name='view'][value='all']"
    assert_select "nav[aria-label='Person view']", count: 0
    assert_select "section[aria-labelledby^='person-category-']", count: 0
    assert_select "a[href='#{person_path(people(:ada))}']", text: /#{categories(:family).name}/
  end

  test "index shows an empty state when there are no people" do
    Person.destroy_all

    get root_url

    assert_response :success
    assert_select "main", /No people yet/
  end

  test "create adds a name-only person without creating entries" do
    assert_difference "Person.count", 1 do
      assert_no_difference "Entry.count" do
        post people_url, params: { person: { name: "Marie Curie" } }
      end
    end

    assert_redirected_to person_url(Person.find_by!(name: "Marie Curie"))
    follow_redirect!
    assert_select "h1", "Marie Curie"
  end

  test "create with a blank name saves nothing and shows the error" do
    assert_no_difference "Person.count" do
      post people_url, params: { person: { name: "" } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /can't be blank/
  end

  test "index only lists the current user's people" do
    get root_url, params: { query: "ada" }

    assert_response :success
    assert_select "input[type='search'][value='ada']"
    assert_select "main", /Ada Lovelace/
    assert_select "main", { text: /Bob Ross/, count: 0 }
  end

  test "index searches the current user's people" do
    get root_url, params: { query: "ada" }

    assert_response :success
    assert_select "main", /Ada Lovelace/
    assert_select "main", { text: /Grace Hopper/, count: 0 }
  end

  test "index applies the selected sort while preserving the query" do
    get root_url, params: { query: "ada", sort: "recently_updated" }

    assert_response :success
    assert_select "input[type='search'][value='ada']"
    assert_select "select[name='sort'] option[selected][value='recently_updated']"
  end

  test "index displays the default sort for an invalid value" do
    get root_url, params: { sort: "updated_at desc" }

    assert_response :success
    assert_select "select[name='sort'] option[selected][value='']", text: "Name"
  end

  test "index does not return another user's person in search results" do
    get root_url, params: { query: "bob" }

    assert_response :success
    assert_select "main", { text: /Bob Ross/, count: 0 }
  end

  test "index returns no people for a query with no matches" do
    get root_url, params: { query: "zzzz" }

    assert_response :success
    assert_select "main", /No people matching 'zzzz'/
    assert_select "main", { text: /Ada Lovelace/, count: 0 }
    assert_select "main", { text: /Grace Hopper/, count: 0 }
  end

  test "show returns 404 for another user's person" do
    get person_url(people(:bob))

    assert_response :not_found
  end

  test "created people belong to the current user" do
    post people_url, params: { person: { name: "Marie Curie" } }

    assert_equal users(:one), Person.find_by!(name: "Marie Curie").user
  end

  test "show displays the person" do
    assert_no_difference -> { people(:ada).interactions.count } do
      get person_url(people(:ada))
    end

    assert_response :success
    assert_select "h1", /Ada Lovelace/
    assert_select "button[aria-label][aria-haspopup='menu']"
    assert_select "[data-controller='toggle'] input[name='person[name]']"
    assert_select "#contact-actions-heading", text: "Contact actions"
    assert_select "[aria-labelledby='contact-actions-heading'] a[href='tel:555-1234'] .break-all", text: "555-1234"
    assert_select "[aria-labelledby='contact-actions-heading'] a[href='mailto:ada@example.com']"
    assert_select "#entries-feed turbo-frame", count: 3
    assert_select "#entries-feed > div.space-y-4"
    assert_select "#entries-feed", /Phone/
    assert_select "#entries-feed", /Email/
    assert_select "#entries-feed", /Birthday/
    all_types_path = Rails.application.routes.url_helpers.new_person_entry_path(people(:ada))
    phone_entry_path = Rails.application.routes.url_helpers.new_person_entry_path(
      people(:ada),
      { type: "Entry::Phone" }
    )
    phone_link = css_select("a").find { |link| link["href"] == phone_entry_path }
    assert_not_nil phone_link
    assert_match(/Phone/, phone_link.text)
    assert_select "a[href='#{all_types_path}']", text: "View all"
    assert_select "button[aria-controls='#{QuickInteractionComponent::DOM_ID}']", text: "Contacted today"
    assert_select "[data-controller~='dialog'][data-dialog-open-value='false'] dialog##{QuickInteractionComponent::DOM_ID}"
    assert_select "form[action='#{person_interactions_path(people(:ada))}']"
    assert_select "p", text: /No contact yet/
    assert_select "#contact-reminder-heading", text: "Keep in touch"
    assert_select "form[action='#{person_keep_in_touch_setting_path(people(:ada))}']"
    assert_select "form[action='#{person_category_assignment_path(people(:ada))}'] select[name='category_assignment[category_id]']"
  end

  test "show links back to the birthday agenda that opened the person" do
    get person_url(people(:ada)), params: { from: "birthdays" }

    assert_response :success
    assert_select "a[href='#{birthdays_path}']", text: /Birthdays/
  end

  test "show links back to a focused birthday month" do
    get person_url(people(:ada)), params: { from: "birthdays", month: 12 }

    assert_response :success
    assert_select "a[href='#{birthdays_path(month: 12)}']", text: /Birthdays/
    assert_select "form[action='#{person_path(people(:ada))}'] input[type='hidden'][name='from'][value='birthdays']"
    assert_select "form[action='#{person_path(people(:ada))}'] input[type='hidden'][name='month'][value='12']"
  end

  test "show does not accept an arbitrary birthday return month" do
    get person_url(people(:ada)), params: { from: "birthdays", month: "outside" }

    assert_response :success
    assert_select "a[href='#{birthdays_path}']", text: /Birthdays/
    assert_select "input[type='hidden'][name='month']", count: 0
  end

  test "show opens the quick interaction dialog when requested by a reminder link" do
    get person_url(people(:ada)), params: { quick_interaction: "today" }

    assert_response :success
    assert_select "[data-controller~='dialog'][data-dialog-open-value='true'] dialog##{QuickInteractionComponent::DOM_ID}"
  end

  test "show displays last contacted label when interactions exist" do
    people(:ada).interactions.create!(occurred_on: users(:one).local_date - 2.days)

    get person_url(people(:ada))

    assert_response :success
    assert_select "#last-contacted", text: /Last contact/
    assert_select "#last-contacted", text: /2 days ago/
  end

  test "show displays the most recent interaction date when multiple exist" do
    people(:ada).interactions.create!(occurred_on: users(:one).local_date - 5.days)
    people(:ada).interactions.create!(occurred_on: users(:one).local_date - 1.day)

    get person_url(people(:ada))

    assert_response :success
    assert_select "#last-contacted", text: /Last contact/
    assert_select "#last-contacted", text: /1 day ago/
  end

  test "show describes older interactions with multiple calendar units" do
    travel_to Time.utc(2026, 4, 15, 12) do
      people(:ada).interactions.create!(occurred_on: Date.new(2026, 3, 1))

      get person_url(people(:ada))

      assert_response :success
      assert_select "#last-contacted", text: /1 month and 2 weeks ago/
    end
  end

  test "show omits the empty entries feed for a person with only a name" do
    person = Current.user.people.create!(name: "Name Only")

    get person_url(person)

    assert_response :success
    assert_select "#entries-feed", count: 0
    assert_select "main", { text: /No entries yet/, count: 0 }
  end

  test "update renames the person" do
    patch person_url(people(:ada)), params: { person: { name: "Ada King" } }

    assert_equal "Ada King", people(:ada).reload.name
    assert_redirected_to person_url(people(:ada))
  end

  test "update with blank name re-renders with error" do
    patch person_url(people(:ada)), params: { person: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "main", /can't be blank/
    assert_select "h1[data-toggle-target='content'].hidden"
    assert_select "[data-toggle-target='content']:not(.hidden) input[name='person[name]']"
  end

  test "destroy removes the person and redirects to root" do
    assert_difference "Person.count", -1 do
      delete person_url(people(:ada))
    end

    assert_redirected_to root_url
  end

  test "same slug resolves to each user's own person" do
    person_one = users(:one).people.create!(name: "María López")
    person_two = users(:two).people.create!(name: "María López")
    assert_equal person_one.slug, person_two.slug

    # User one sees their own María López
    get person_url(person_one)
    assert_response :success
    assert_select "h1", /María López/

    # User two sees their own María López at the same URL
    sign_in_as users(:two)
    get person_url(person_two)
    assert_response :success
    assert_select "h1", /María López/

    # A slug that exists only for user two returns 404 for user one
    person_three = users(:two).people.create!(name: "Único Amigo")
    sign_in_as users(:one)
    get person_url(person_three)
    assert_response :not_found
  end

  test "cross-user returns 404 for update" do
    patch person_url(people(:bob)), params: { person: { name: "Nope" } }

    assert_response :not_found
  end

  test "cross-user returns 404 for destroy" do
    delete person_url(people(:bob))

    assert_response :not_found
  end
end
