class InteractionFormComponent < ViewComponent::Base
  def initialize(person:, interaction:)
    @person = person
    @interaction = interaction
  end

  private

  attr_reader :person, :interaction

  def enabled_contact_methods
    @enabled_contact_methods ||= person.user.contact_methods.enabled.ordered.to_a
  end
end
