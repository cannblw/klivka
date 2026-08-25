require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    post friend_entries_url(friends(:ada)), params: { entry: { type: "Entry::Phone", content: { number: "123" } } }

    assert_redirected_to new_session_url
  end

  test "new redirects to sign in when unauthenticated" do
    sign_out

    get new_friend_entry_url(friends(:ada))

    assert_redirected_to new_session_url
  end

  test "create adds an entry to the friend" do
    assert_difference -> { friends(:ada).entries.count }, 1 do
      post friend_entries_url(friends(:ada)),
        params: { entry: { type: "Entry::Phone", content: { number: "555-9876" } } }
    end

    assert_redirected_to friend_url(friends(:ada))
    entry = friends(:ada).entries.last
    assert_equal "Entry::Phone", entry.type
    assert_equal "555-9876", entry.content["number"]
    assert_equal entry, friends(:ada).entries.ordered.first
  end

  test "reorder saves the requested entry order" do
    ordered_ids = [ entries(:ada_birthday).id, entries(:email).id, entries(:phone).id ]

    patch reorder_friend_entries_url(friends(:ada)),
      params: { entry_ids: ordered_ids },
      as: :json

    assert_response :no_content
    assert_equal ordered_ids, friends(:ada).entries.ordered.pluck(:id)
  end

  test "reorder rejects an incomplete order without changing anything" do
    original_ids = friends(:ada).entries.ordered.pluck(:id)

    patch reorder_friend_entries_url(friends(:ada)),
      params: { entry_ids: [ entries(:phone).id, entries(:email).id ] },
      as: :json

    assert_response :unprocessable_entity
    assert_equal original_ids, friends(:ada).entries.ordered.pluck(:id)
  end

  test "reorder rejects a missing order" do
    patch reorder_friend_entries_url(friends(:ada)), params: {}, as: :json

    assert_response :unprocessable_entity
  end

  test "reorder rejects a duplicate order without changing anything" do
    original_ids = friends(:ada).entries.ordered.pluck(:id)

    patch reorder_friend_entries_url(friends(:ada)),
      params: { entry_ids: [ entries(:phone).id, entries(:phone).id, entries(:ada_birthday).id ] },
      as: :json

    assert_response :unprocessable_entity
    assert_equal original_ids, friends(:ada).entries.ordered.pluck(:id)
  end

  test "reorder rejects an entry belonging to another friend" do
    patch reorder_friend_entries_url(friends(:ada)),
      params: { entry_ids: [ entries(:phone).id, entries(:email).id, entries(:note).id ] },
      as: :json

    assert_response :unprocessable_entity
  end

  test "reorder returns 404 for another user's friend" do
    patch reorder_friend_entries_url(friends(:bob)), params: { entry_ids: [] }, as: :json

    assert_response :not_found
  end

  test "generic date entries render in the profile feed" do
    post friend_entries_url(friends(:ada)),
      params: {
        entry: {
          type: "Entry::Date",
          entry_date: "2020-01-02",
          content: { label: "Dad's first iguana" }
        }
      }

    assert_redirected_to friend_url(friends(:ada))
    follow_redirect!
    assert_select "#entries-feed", /Date/
    assert_select "#entries-feed", /Dad's first iguana/
  end

  test "create saves an enabled reminder with its own lead time" do
    assert_difference -> { EntryReminder.count }, 1 do
      post friend_entries_url(friends(:ada)),
        params: {
          entry: {
            type: "Entry::Date",
            entry_date: "2020-01-02",
            content: { label: "Wedding anniversary" },
            entry_reminder_attributes: { lead_value: "1", lead_unit: "days", recurrence: EntryReminder::YEARLY_RECURRENCE, _destroy: "0" }
          }
        }
    end

    reminder = friends(:ada).entries.where(type: "Entry::Date").order(:id).last.entry_reminder
    assert_redirected_to friend_url(friends(:ada))
    assert_equal 1, reminder.lead_value
    assert_equal "days", reminder.lead_unit
    assert_equal EntryReminder::YEARLY_RECURRENCE, reminder.recurrence
  end

  test "create leaves a date reminder off when a reminder is not added" do
    assert_no_difference -> { EntryReminder.count } do
      post friend_entries_url(friends(:ada)),
        params: {
          entry: {
            type: "Entry::Date",
            entry_date: "2020-01-02",
            content: { label: "Wedding anniversary" },
            entry_reminder_attributes: { lead_value: "1", lead_unit: "months", _destroy: "1" }
          }
        }
    end

    entry = friends(:ada).entries.where(type: "Entry::Date").order(:id).last
    assert_redirected_to friend_url(friends(:ada))
    assert_nil entry.entry_reminder
  end

  test "an invalid enabled reminder stays enabled when the date form is rendered again" do
    assert_no_difference -> { EntryReminder.count } do
      post friend_entries_url(friends(:ada)),
        params: {
          entry: {
            type: "Entry::Date",
            entry_date: "2020-01-02",
            content: { label: "Wedding anniversary" },
            entry_reminder_attributes: { lead_value: "-1", lead_unit: "days", _destroy: "0" }
          }
        }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='entry[entry_reminder_attributes][_destroy]'][type='hidden'][value='0']", visible: :all
    assert_select "#entry-reminder-options:not(.hidden)"
    assert_select "input[name='entry[entry_reminder_attributes][lead_value]'][value='-1']"
    assert_select "main", /Reminder amount must be greater than or equal to 0/
  end

  test "create adds a normalized email entry" do
    assert_difference -> { friends(:ada).entries.count }, 1 do
      post friend_entries_url(friends(:ada)),
        params: { entry: { type: "Entry::Email", content: { email: "  ADA@EXAMPLE.COM ", label: "Work" } } }
    end

    assert_redirected_to friend_url(friends(:ada))
    entry = friends(:ada).entries.last
    assert_equal "Entry::Email", entry.type
    assert_equal "ada@example.com", entry.content["email"]
    assert_equal "Work", entry.content["label"]
  end

  test "explicitly creating First Met with a month and year preserves its precision" do
    assert_difference -> { friends(:ada).entries.where(type: "Entry::FirstMet").count }, 1 do
      post friend_entries_url(friends(:ada)),
        params: {
          entry: {
            type: "Entry::FirstMet",
            entry_year: "2020",
            entry_month: "1",
            content: { note: "At the market" }
          }
        }
    end

    first_met = friends(:ada).entries.find_by!(type: "Entry::FirstMet")
    assert_redirected_to friend_url(friends(:ada))
    assert_equal Date.new(2020, 1, 1), first_met.entry_date
    assert_equal "month", first_met.date_precision
    assert_equal "month", first_met.content["date_precision"]

    follow_redirect!
    assert_select "#entries-feed", /January 2020/
  end

  test "create adds a gift-list entry from indexed form items" do
    assert_difference -> { friends(:ada).entries.where(type: "Entry::GiftList").count }, 1 do
      post friend_entries_url(friends(:ada)),
        params: {
          entry: {
            type: "Entry::GiftList",
            content: {
              title: "Ideas",
              items: {
                "0" => { text: "Iguana hammock", checked: "0" },
                "1" => { text: " " }
              }
            }
          }
        }
    end

    entry = friends(:ada).entries.where(type: "Entry::GiftList").last
    assert_redirected_to friend_url(friends(:ada))
    assert_equal [ "Iguana hammock" ], entry.items.pluck("text")
  end

  test "update preserves gift-list item order and completion" do
    entry = Entry::GiftList.create!(
      friend: friends(:ada),
      items: [ { text: "Book" }, { text: "Scarf" } ]
    )
    book, scarf = entry.items

    patch friend_entry_url(friends(:ada), entry),
      params: {
        entry: {
          content: {
            items: {
              "1" => { id: scarf["id"], text: scarf["text"], checked: "1" },
              "0" => { id: book["id"], text: book["text"] }
            }
          }
        }
      },
      headers: { "Turbo-Frame" => "true" }

    assert_response :success
    assert_equal [ "Scarf", "Book" ], entry.reload.items.pluck("text")
    assert_equal [ true, false ], entry.items.pluck("checked")
  end

  test "create with an invalid email re-renders only the email form" do
    assert_no_difference -> { friends(:ada).entries.count } do
      post friend_entries_url(friends(:ada)),
        params: { entry: { type: "Entry::Email", content: { email: "not-an-email" } } }
    end

    assert_response :unprocessable_entity
    assert_select "#email-fields input[type='email'][value='not-an-email']"
    assert_select "#phone-fields", count: 0
    assert_select "main", /Email/
  end

  test "create rejects an unsupported entry type" do
    assert_no_difference -> { friends(:ada).entries.count } do
      post friend_entries_url(friends(:ada)),
        params: { entry: { type: "User", content: {} } }
    end

    assert_response :unprocessable_entity
    assert_select "main", /Type/
  end

  test "create with a missing entry type returns an error" do
    assert_no_difference -> { friends(:ada).entries.count } do
      post friend_entries_url(friends(:ada)), params: { entry: { content: { email: "ada@example.com" } } }
    end

    assert_response :unprocessable_entity
  end

  test "create with validation error re-renders the selected form" do
    post friend_entries_url(friends(:ada)),
      params: { entry: { type: "Entry::Birthday", entry_date: "" } }

    assert_response :unprocessable_entity
    assert_select "h1", "Add Birthday to Ada Lovelace"
    assert_select "#birthday-fields"
  end

  test "edit renders the form" do
    get edit_friend_entry_url(friends(:ada), entries(:phone))

    assert_response :success
    assert_select "turbo-frame"
    assert_select "form"
  end

  test "new without a type shows every searchable entry type" do
    get new_friend_entry_url(friends(:ada))

    assert_response :success
    assert_select "input[type='search'][data-action='input->filter-list#filter']"
    Entry::CREATABLE_TYPES.each do |type|
      label = I18n.t("entries.kinds.#{type.demodulize.underscore}")
      assert_select "li[data-search-value='#{label}']"
    end
    assert_select "[data-entry-type-unavailable]", /Birthday.*Added/
  end

  test "new returns 404 for another user's friend" do
    get new_friend_entry_url(friends(:bob))

    assert_response :not_found
  end

  test "new with a type shows only that type's form" do
    get new_friend_entry_url(friends(:ada), type: "Entry::Date")

    assert_response :success
    assert_select "input[name='entry[type]'][value='Entry::Date']"
    assert_select "#date-fields"
    assert_select "#phone-fields", count: 0
  end

  test "update saves changes and renders the card" do
    entry = friends(:ada).entries.create!(type: "Entry::Note", content: { text: "old" })

    patch friend_entry_url(friends(:ada), entry),
      params: { entry: { content: { text: "updated" } } },
      headers: { "Turbo-Frame" => "true" }

    assert_response :success
    assert_equal "updated", entry.reload.content["text"]
    assert_select "turbo-frame"
  end

  test "update removes an existing date reminder" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 1, 2))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "months")

    patch friend_entry_url(friends(:ada), entry),
      params: { entry: { entry_reminder_attributes: { id: reminder.id, _destroy: "1" } } },
      headers: { "Turbo-Frame" => "true" }

    assert_response :success
    assert_nil entry.reload.entry_reminder
    assert_select "[data-entry-reminder-summary]", count: 0
  end

  test "update changes an existing date reminder" do
    entry = Entry::Date.create!(friend: friends(:ada), entry_date: Date.new(2020, 1, 2))
    reminder = entry.create_entry_reminder!(lead_value: 1, lead_unit: "months")

    patch friend_entry_url(friends(:ada), entry),
      params: {
        entry: {
          entry_reminder_attributes: {
            id: reminder.id,
            lead_value: "2",
            lead_unit: "days",
            recurrence: EntryReminder::YEARLY_RECURRENCE,
            _destroy: "0"
          }
        }
      },
      headers: { "Turbo-Frame" => "true" }

    assert_response :success
    reminder.reload
    assert_equal 2, reminder.lead_value
    assert_equal "days", reminder.lead_unit
    assert_predicate reminder, :yearly?
  end

  test "update normalizes an email and renders its mail link" do
    patch friend_entry_url(friends(:ada), entries(:email)),
      params: { entry: { content: { email: " NEW@EXAMPLE.COM ", label: " Personal " } } },
      as: :turbo_stream

    assert_response :success
    assert_equal "new@example.com", entries(:email).reload.email
    assert_equal "Personal", entries(:email).label
    assert_select "turbo-stream[action='replace'][target='#{ActionView::RecordIdentifier.dom_id(entries(:email))}']"
    assert_select "turbo-stream[action='replace'][target='friend_contact_actions']"
    assert_select "a[href='mailto:new@example.com']", text: "new@example.com"
  end

  test "update with an invalid email re-renders the edit form" do
    patch friend_entry_url(friends(:ada), entries(:email)),
      params: { entry: { content: { email: "invalid", label: "Work" } } }

    assert_response :unprocessable_entity
    assert_select "#email-fields input[type='email'][value='invalid']"
    assert_select "main", /Email/
  end

  test "update with validation error re-renders edit form" do
    birthday = entries(:ada_birthday)

    patch friend_entry_url(friends(:ada), birthday),
      params: { entry: { entry_date: "" } }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "destroy removes the entry" do
    entry = friends(:ada).entries.create!(type: "Entry::Note", content: { text: "to delete" })

    assert_difference -> { friends(:ada).entries.count }, -1 do
      delete friend_entry_url(friends(:ada), entry), as: :turbo_stream
    end

    assert_response :success
    assert_select "turbo-stream[action='remove'][target='#{ActionView::RecordIdentifier.dom_id(entry)}']"
    assert_select "turbo-stream[action='replace'][target='friend_contact_actions']"
  end

  test "cross-user returns 404 for edit" do
    get edit_friend_entry_url(friends(:bob), entries(:phone))

    assert_response :not_found
  end

  test "cross-user returns 404 for update" do
    patch friend_entry_url(friends(:bob), entries(:phone)),
      params: { entry: { content: { number: "no" } } }

    assert_response :not_found
  end

  test "cross-user returns 404 for destroy" do
    delete friend_entry_url(friends(:bob), entries(:phone))

    assert_response :not_found
  end
end
