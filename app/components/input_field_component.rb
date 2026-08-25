class InputFieldComponent < ViewComponent::Base
  include FormStyling

  FIELD_TYPES = {
    text: :text_field,
    email: :email_field,
    password: :password_field,
    search: :search_field,
    number: :number_field,
    date: :date_field
  }.freeze

  def initialize(form, field, type:, **options)
    @form = form
    @field = field
    @field_type = type.to_sym
    @options = options
  end

  private

  attr_reader :form, :field, :options

  def input_classes
    [ INPUT_CLASSES, options.delete(:class) ].compact.join(" ")
  end

  def field_method
    FIELD_TYPES.fetch(@field_type)
  end
end
