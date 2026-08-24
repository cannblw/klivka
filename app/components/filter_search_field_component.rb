class FilterSearchFieldComponent < ViewComponent::Base
  def initialize(id:, label:, placeholder:, **options)
    @id = id
    @label = label
    @placeholder = placeholder
    @extra_classes = options.delete(:class)
    @data = { action: "input->filter-list#filter" }.merge(options.delete(:data) || {})
    @options = options
  end

  private

  attr_reader :id, :label, :placeholder, :data, :options

  def input_classes
    base = "w-full rounded-lg border border-stone-300 bg-stone-50 px-3 py-2 text-sm focus:border-amber-500 focus:outline-none focus:ring-1 focus:ring-amber-500 dark:border-stone-600 dark:bg-stone-800 dark:text-stone-100"
    [ base, @extra_classes ].compact.join(" ")
  end
end
