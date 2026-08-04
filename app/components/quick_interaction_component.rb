class QuickInteractionComponent < ViewComponent::Base
  DOM_ID = "quick-interaction-dialog"

  def initialize(friend:, interaction:, open: false)
    @friend = friend
    @interaction = interaction
    @open = open
  end

  private

  attr_reader :friend, :interaction

  def open?
    @open
  end

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
