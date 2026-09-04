require "test_helper"

class ContactMethodManagementComponentTest < ViewComponent::TestCase
  test "provided methods render reorder, edit, and reversible remove controls" do
    contact_method = contact_methods(:one_call)
    routes = Rails.application.routes.url_helpers

    render_inline ContactMethodManagementComponent.new(contact_method:)

    assert_selector "[data-contact-method-id='#{contact_method.id}']"
    assert_selector "[data-contact-method-sortable-target='handle'][aria-label]"
    assert_selector "form[action='#{routes.disable_contact_method_path(contact_method)}']"
    assert_selector "form[action='#{routes.contact_method_path(contact_method)}'] input[name='contact_method[name]']"
    assert_no_selector "[data-controller='confirm-dialog-trigger']"
  end

  test "custom methods render confirmed permanent deletion" do
    contact_method = users(:one).contact_methods.create!(name: "Letters", enabled: true, position: 7)
    routes = Rails.application.routes.url_helpers

    render_inline ContactMethodManagementComponent.new(contact_method:)

    assert_selector "[data-controller='confirm-dialog-trigger'][data-confirm-dialog-url='#{routes.contact_method_path(contact_method)}'][data-confirm-dialog-turbo-method='delete']"
    assert_no_selector "form[action='#{routes.disable_contact_method_path(contact_method)}']"
  end

  test "validation errors reveal the edit form" do
    contact_method = contact_methods(:one_call)
    contact_method.name = ""
    contact_method.validate
    path = Rails.application.routes.url_helpers.contact_method_path(contact_method)

    render_inline ContactMethodManagementComponent.new(contact_method:)

    assert_selector "[data-toggle-target='content']:not(.hidden) form[action='#{path}']"
    assert_selector ".text-red-600"
  end
end
