class QuickInteractionComponent < ViewComponent::Base
  DOM_ID = "quick-interaction-dialog"

  def initialize(person:, interaction:, time_zone:, open: false, dom_id: DOM_ID, button_label: nil, return_to: nil)
    @person = person
    @interaction = interaction
    @time_zone = time_zone
    @open = open
    @dom_id = dom_id
    @button_label = button_label
    @return_to = return_to
  end

  private

  attr_reader :person, :interaction, :time_zone, :dom_id, :return_to

  def open?
    @open
  end

  def button_label
    @button_label || t("interactions.contacted_today.button")
  end

  def heading_id
    "#{dom_id}-heading"
  end

  def contact_method_options
    Interaction::CONTACT_METHODS.map { |method| [ t("interactions.methods.#{method}"), method ] }
  end
end
