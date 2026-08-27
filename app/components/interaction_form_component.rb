class InteractionFormComponent < ViewComponent::Base
  def initialize(person:, interaction:)
    @person = person
    @interaction = interaction
  end

  private

  attr_reader :person, :interaction

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
