require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "redirects to sign in when unauthenticated" do
    sign_out
    post friend_entries_url(friends(:ada)), params: { entry: { type: "Entry::Phone", content: { number: "123" } } }

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
  end

  test "create with validation error re-renders friend page" do
    post friend_entries_url(friends(:ada)),
      params: { entry: { type: "Entry::Birthday", entry_date: "" } }

    assert_response :unprocessable_entity
    assert_select "h1", "Ada Lovelace"
  end

  test "edit renders the form" do
    get edit_friend_entry_url(friends(:ada), entries(:phone))

    assert_response :success
    assert_select "turbo-frame"
    assert_select "form"
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
