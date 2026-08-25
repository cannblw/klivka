class FilterSearchFieldComponent < ViewComponent::Base
  include FormStyling

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
    [ INPUT_CLASSES, @extra_classes ].compact.join(" ")
  end
end
