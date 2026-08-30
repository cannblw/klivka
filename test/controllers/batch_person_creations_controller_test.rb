require "test_helper"

class BatchPersonCreationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "batch person entry requires authentication" do
    sign_out

    get new_batch_person_creation_url

    assert_redirected_to new_session_url
  end

  test "batch person entry is available in the shared demo" do
    with_demo_mode do
      get new_batch_person_creation_url

      assert_redirected_to people_url(batch: true)
    end
  end

  test "person dialog offers single and batch creation modes" do
    get people_url

    assert_response :success
    assert_select "a[href='#{new_batch_person_creation_path}']", count: 0
    assert_select "form[action='#{people_path}'] input[name='person[name]']"
    assert_select "form[action='#{preview_batch_person_creation_path}'][data-turbo='false'] textarea[name='batch_person_creation[names]']"
    assert_select "[data-action='toggle#toggle']", minimum: 2
  end

  test "batch person dialog renders in the user's locale" do
    users(:one).update!(locale: "es")

    get people_url(batch: true)

    assert_response :success
    assert_select "html[lang='es']"
    assert_select "[data-dialog-open-value='true']"
    assert_select "textarea[name='batch_person_creation[names]']"
  end

  test "preview shows normalized editable candidates selected by default" do
    post preview_batch_person_creation_url, params: {
      batch_person_creation: { names: "  Marie   Curie \n Katherine Johnson " }
    }

    assert_response :success
    assert_select "form[action='#{batch_person_creation_path}']"
    assert_select "input[type='text'][value='Marie Curie']"
    assert_select "input[type='text'][value='Katherine Johnson']"
    assert_select "input[type='checkbox'][checked]", count: 2
  end

  test "preview identifies possible duplicates without deselecting them" do
    post preview_batch_person_creation_url, params: {
      batch_person_creation: { names: "Ada Lovelace\nada lovelace" }
    }

    assert_response :success
    assert_select "li [role='note']", count: 2
    assert_select "input[type='checkbox'][checked]", count: 2
  end

  test "preview rejects input without names" do
    post preview_batch_person_creation_url, params: { batch_person_creation: { names: " \n " } }

    assert_response :unprocessable_entity
    assert_select "[data-dialog-open-value='true']"
    assert_select "textarea[aria-invalid='true']"
    assert_select "form[data-controller='search']"
    assert_select "details:not([open]) summary", text: /More options/
  end

  test "create adds edited selected people and reports skipped names" do
    assert_difference -> { users(:one).people.count }, 2 do
      post batch_person_creation_url, params: {
        batch_person_creation: {
          candidates: {
            "0" => { id: "0", name: "Marie Curie", selected: "1" },
            "1" => { id: "1", name: "Skip Me", selected: "0" },
            "2" => { id: "2", name: "  Katherine   Johnson ", selected: "1" }
          }
        }
      }
    end

    assert_redirected_to people_url
    assert_equal [ "Katherine Johnson", "Marie Curie" ], users(:one).people.where(name: [ "Marie Curie", "Katherine Johnson" ]).order(:name).pluck(:name)
    follow_redirect!
    assert_select "[role='status']", /2 people added.*One name skipped/m
  end

  test "create writes every person to the current user" do
    assert_no_difference -> { users(:two).people.count } do
      post batch_person_creation_url, params: {
        batch_person_creation: { candidates: { "0" => { id: "0", name: "Marie Curie", selected: "1" } } }
      }
    end

    assert users(:one).people.exists?(name: "Marie Curie")
  end

  test "create saves nothing and returns to review when a selected name is invalid" do
    assert_no_difference "Person.count" do
      post batch_person_creation_url, params: {
        batch_person_creation: {
          candidates: {
            "0" => { id: "0", name: "Marie Curie", selected: "1" },
            "1" => { id: "1", name: "", selected: "1" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[aria-invalid='true']"
  end

  test "create rejects a request without candidates" do
    assert_no_difference "Person.count" do
      post batch_person_creation_url, params: { batch_person_creation: {} }
    end

    assert_response :unprocessable_entity
  end
end
