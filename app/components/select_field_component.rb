class SelectFieldComponent < ViewComponent::Base
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
    base = "w-full appearance-none rounded-lg border border-stone-300 bg-stone-50 px-3 py-2 pr-10 text-sm focus:border-amber-500 focus:outline-none focus:ring-1 focus:ring-amber-500 dark:border-stone-600 dark:bg-stone-800 dark:text-stone-100"
    [ base, options.delete(:class) ].compact.join(" ")
  end

  def wrapper_classes
    [ "relative", wrapper_class ].compact.join(" ")
  end
end
