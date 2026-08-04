class InteractionFormComponent < ViewComponent::Base
  def initialize(friend:, interaction:)
    @friend = friend
    @interaction = interaction
  end

  private

  attr_reader :friend, :interaction

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
