class QuickInteractionComponent < ViewComponent::Base
  DOM_ID = "quick-interaction-dialog"

  def initialize(person:, interaction:, time_zone:, open: false)
    @person = person
    @interaction = interaction
    @time_zone = time_zone
    @open = open
  end

  private

  attr_reader :person, :interaction, :time_zone

  def open?
    @open
  end

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
