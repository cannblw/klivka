class SelectFieldComponent < ViewComponent::Base
  include FormStyling

  def initialize(form, field, choices:, selected: nil, select_options: {}, wrapper_class: nil, **options)
    @form = form
    @field = field
    @choices = choices
    @selected = selected
    @select_options = select_options
    @wrapper_class = wrapper_class
    @options = options
  end

  private

  attr_reader :form, :field, :choices, :selected, :select_options, :wrapper_class, :options

  def selected_options
    { selected: selected }.merge(select_options)
  end

  def select_classes
    base = "#{INPUT_CLASSES} appearance-none pr-10"
    [ base, options.delete(:class) ].compact.join(" ")
  end

  def wrapper_classes
    [ "relative", wrapper_class ].compact.join(" ")
  end
end
