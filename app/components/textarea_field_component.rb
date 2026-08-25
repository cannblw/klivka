class TextareaFieldComponent < ViewComponent::Base
  def initialize(form, field, **options)
    @form = form
    @field = field
    @options = options
  end

  private

  attr_reader :form, :field, :options

  def textarea_classes
    base = "w-full resize-none rounded-lg border border-stone-300 bg-stone-50 px-3 py-2 text-sm focus:border-amber-500 focus:outline-none focus:ring-1 focus:ring-amber-500 dark:border-stone-600 dark:bg-stone-800 dark:text-stone-100"
    [ base, options.delete(:class) ].compact.join(" ")
  end
end
