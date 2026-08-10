class QuickInteractionComponent < ViewComponent::Base
  DOM_ID = "quick-interaction-dialog"

  def initialize(friend:, interaction:, time_zone:, open: false)
    @friend = friend
    @interaction = interaction
    @time_zone = time_zone
    @open = open
  end

  private

  attr_reader :friend, :interaction, :time_zone

  def open?
    @open
  end

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
