class ContactMethodManagementComponent < ViewComponent::Base
  with_collection_parameter :contact_method

  def initialize(contact_method:)
    @contact_method = contact_method
  end

  private

  attr_reader :contact_method

  def heading_id
    "contact-method-#{contact_method.id}-name"
  end
end
