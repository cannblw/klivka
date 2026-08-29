class InteractionFormComponent < ViewComponent::Base
  include ContactMethodSelectable

  def initialize(person:, interaction:)
    @person = person
    @interaction = interaction
  end

  private

  attr_reader :person, :interaction
end
