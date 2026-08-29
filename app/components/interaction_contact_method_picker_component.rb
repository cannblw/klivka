class InteractionContactMethodPickerComponent < ViewComponent::Base
  Option = Data.define(:name, :value, :icon_library, :icon_name)

  def initialize(form:, interaction:, contact_methods:)
    @form = form
    @interaction = interaction
    @contact_methods = contact_methods
  end

  private

  attr_reader :form, :interaction, :contact_methods

  def options
    [ blank_option, historical_option, *contact_method_options ].compact
  end

  def blank_option
    Option.new(name: t("interactions.follow_up.method_blank"), value: "", icon_library: nil, icon_name: nil)
  end

  def historical_option
    return if interaction.contact_method_name.blank? || matching_contact_method

    Option.new(
      name: interaction.contact_method_name,
      value: Interaction::PRESERVE_CONTACT_METHOD_VALUE,
      icon_library: interaction.contact_method_icon_library,
      icon_name: interaction.contact_method_icon_name
    )
  end

  def contact_method_options
    contact_methods.map do |contact_method|
      Option.new(
        name: contact_method.name,
        value: contact_method.id,
        icon_library: contact_method.icon_library,
        icon_name: contact_method.icon_name
      )
    end
  end

  def selected_value
    interaction.contact_method_id.presence || matching_contact_method&.id ||
      (Interaction::PRESERVE_CONTACT_METHOD_VALUE if interaction.contact_method_name.present?)
  end

  def matching_contact_method
    @matching_contact_method ||= contact_methods.find do |contact_method|
      contact_method.name == interaction.contact_method_name &&
        contact_method.icon_library == interaction.contact_method_icon_library &&
        contact_method.icon_name == interaction.contact_method_icon_name
    end
  end
end
