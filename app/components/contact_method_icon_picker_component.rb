class ContactMethodIconPickerComponent < ViewComponent::Base
  def initialize(form:, selected: nil)
    @form = form
    @selected = selected
  end

  private

  attr_reader :form, :selected

  def icon_options
    [ [ nil, nil ], *ContactMethodIcons::OPTIONS ]
  end

  def option_value(library, name)
    [ library, name ].compact.join(":")
  end

  def option_label(library, name)
    return t("contact_methods.icons.none") if library.nil?

    t(ContactMethodIcons.label_key(library, name))
  end
end
