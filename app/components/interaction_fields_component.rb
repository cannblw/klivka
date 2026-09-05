class InteractionFieldsComponent < ViewComponent::Base
  def initialize(form:, interaction:, note_rows:)
    @form = form
    @interaction = interaction
    @note_rows = note_rows
  end

  private

  attr_reader :form, :interaction, :note_rows

  def enabled_contact_methods
    @enabled_contact_methods ||= interaction.person.user.contact_methods.enabled.ordered.to_a
  end
end
