class TextareaFieldComponent < ViewComponent::Base
  include FormStyling

  def initialize(form, field, **options)
    @form = form
    @field = field
    @options = options
  end

  private

  attr_reader :form, :field, :options

  def textarea_classes
    [ TEXTAREA_CLASSES, options.delete(:class) ].compact.join(" ")
  end
end
