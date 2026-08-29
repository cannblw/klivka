module ContactMethodSelectable
  private

  def contact_method_options
    options = enabled_contact_methods.map { |contact_method| [ contact_method.name, contact_method.id ] }
    return options if interaction.contact_method_name.blank?

    [ [ interaction.contact_method_name, Interaction::PRESERVE_CONTACT_METHOD_VALUE ], *options ]
  end

  def selected_contact_method
    interaction.contact_method_id.presence ||
      (Interaction::PRESERVE_CONTACT_METHOD_VALUE if interaction.contact_method_name.present?)
  end

  def enabled_contact_methods
    @enabled_contact_methods ||= person.user.contact_methods.enabled.ordered.to_a
  end
end
