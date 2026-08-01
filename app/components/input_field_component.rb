class InputFieldComponent < ViewComponent::Base
  FIELD_TYPES = {
    text: :text_field,
    email: :email_field,
    password: :password_field,
    search: :search_field
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
    base = "rounded-lg border border-stone-300 bg-stone-50 px-3 py-2 text-sm focus:border-amber-500 focus:outline-none focus:ring-1 focus:ring-amber-500 dark:border-stone-600 dark:bg-stone-800 dark:text-stone-100"
    [ base, options.delete(:class) ].compact.join(" ")
  end

  def field_method
    FIELD_TYPES.fetch(@field_type)
  end
end
