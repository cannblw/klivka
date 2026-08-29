require "test_helper"

class ContactMethodsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "contact methods require authentication" do
    sign_out

    get contact_methods_url

    assert_redirected_to new_session_url
  end

  test "index shows the current user's enabled methods and available provided methods" do
    get contact_methods_url

    assert_response :success
    assert_select "h1", "Contact methods"
    assert_select "[data-contact-method-id='#{contact_methods(:one_call).id}']"
    assert_select "[data-contact-method-id='#{contact_methods(:two_call).id}']", count: 0
    assert_select "form[action='#{enable_contact_method_path(contact_methods(:one_wechat))}']"
    assert_select "form[action='#{enable_contact_method_path(contact_methods(:two_wechat))}']", count: 0
    assert_select "form[action='#{contact_methods_path}'] input[name='contact_method[name]']"
  end

  test "create adds an enabled custom method at the end of the current order" do
    assert_difference -> { users(:one).contact_methods.count }, 1 do
      post contact_methods_url, params: {
        contact_method: { name: "Letters", icon: "material_icons:email" }
      }
    end

    contact_method = users(:one).contact_methods.find_by!(normalized_name: "letters")
    assert_redirected_to contact_methods_url
    assert_predicate contact_method, :enabled?
    assert_not_predicate contact_method, :provided?
    assert_equal 7, contact_method.position
    assert_equal "material_icons", contact_method.icon_library
    assert_equal "email", contact_method.icon_name
  end

  test "create shows validation errors without adding a duplicate method" do
    assert_no_difference "ContactMethod.count" do
      post contact_methods_url, params: {
        contact_method: { name: "  WHATSAPP  ", icon: "simple_icons:whatsapp" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action='#{contact_methods_path}'] .text-red-600"
  end

  test "update changes an enabled method's literal name and icon" do
    contact_method = contact_methods(:one_call)

    patch contact_method_url(contact_method), params: {
      contact_method: { name: "Phone", icon: "material_icons:chat" }
    }

    assert_redirected_to contact_methods_url
    assert_equal "Phone", contact_method.reload.name
    assert_equal "phone", contact_method.normalized_name
    assert_equal "material_icons", contact_method.icon_library
    assert_equal "chat", contact_method.icon_name
  end

  test "update cannot change another user's contact method" do
    contact_method = contact_methods(:two_call)

    patch contact_method_url(contact_method), params: {
      contact_method: { name: "Changed", icon: "" }
    }

    assert_response :not_found
    assert_equal "Call", contact_method.reload.name
  end

  test "enable adds a provided method at the end of the current order" do
    contact_method = contact_methods(:one_wechat)

    patch enable_contact_method_url(contact_method)

    assert_redirected_to contact_methods_url
    assert_predicate contact_method.reload, :enabled?
    assert_equal 7, contact_method.position
  end

  test "enable cannot add another user's provided method" do
    contact_method = contact_methods(:two_wechat)

    patch enable_contact_method_url(contact_method)

    assert_response :not_found
    assert_not_predicate contact_method.reload, :enabled?
  end

  test "disable removes a provided method and compacts the remaining order" do
    contact_method = contact_methods(:one_text_message)

    patch disable_contact_method_url(contact_method)

    assert_redirected_to contact_methods_url
    assert_not_predicate contact_method.reload, :enabled?
    assert_nil contact_method.position
    assert_equal (0..5).to_a, users(:one).contact_methods.enabled.ordered.pluck(:position)
  end

  test "disable does not remove a custom method" do
    contact_method = users(:one).contact_methods.create!(name: "Letters", enabled: true, position: 7)

    patch disable_contact_method_url(contact_method)

    assert_response :not_found
    assert_predicate contact_method.reload, :enabled?
  end

  test "destroy permanently deletes a custom method and compacts the order" do
    contact_method = users(:one).contact_methods.create!(name: "Letters", enabled: true, position: 7)

    assert_difference "ContactMethod.count", -1 do
      delete contact_method_url(contact_method)
    end

    assert_redirected_to contact_methods_url
    assert_equal (0..6).to_a, users(:one).contact_methods.enabled.ordered.pluck(:position)
  end

  test "destroying a custom method preserves its interaction snapshots" do
    contact_method = users(:one).contact_methods.create!(
      name: "Letters", icon_library: "material_icons", icon_name: "email", enabled: true, position: 7
    )
    interaction = people(:ada).interactions.new(occurred_on: Date.current)
    interaction.snapshot_contact_method(contact_method)
    interaction.save!

    delete contact_method_url(contact_method)

    assert_equal "Letters", interaction.reload.contact_method_name
    assert_equal "material_icons", interaction.contact_method_icon_library
    assert_equal "email", interaction.contact_method_icon_name
  end

  test "destroy does not delete a provided method" do
    contact_method = contact_methods(:one_call)

    assert_no_difference "ContactMethod.count" do
      delete contact_method_url(contact_method)
    end

    assert_response :not_found
  end

  test "reorder saves every enabled method in the requested order" do
    contact_methods = users(:one).contact_methods.enabled.ordered.to_a
    requested_ids = contact_methods.reverse.map(&:id)

    patch reorder_contact_methods_url, params: { contact_method_ids: requested_ids }, as: :json

    assert_response :no_content
    assert_equal requested_ids, users(:one).contact_methods.enabled.ordered.pluck(:id)
  end

  test "reorder rejects incomplete and cross-tenant orders" do
    original_ids = users(:one).contact_methods.enabled.ordered.pluck(:id)
    invalid_ids = original_ids.drop(1) + [ contact_methods(:two_call).id ]

    patch reorder_contact_methods_url, params: { contact_method_ids: invalid_ids }, as: :json

    assert_response :unprocessable_entity
    assert_equal original_ids, users(:one).contact_methods.enabled.ordered.pluck(:id)
  end
end
