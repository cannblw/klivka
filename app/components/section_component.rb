class SectionComponent < ViewComponent::Base
  def initialize(title: nil, description: nil, heading_id: nil, **options)
    @title = title
    @description = description
    @heading_id = heading_id
    @extra_classes = options.delete(:class)
    @options = options
  end

  private

  attr_reader :title, :description, :heading_id, :options

  def classes
    [
      "rounded-xl border border-stone-200 bg-stone-50 p-5 dark:border-stone-700 dark:bg-stone-800",
      @extra_classes
    ].compact.join(" ")
  end

  def section_options
    return options unless title && heading_id

    options.merge(aria: { labelledby: heading_id }.merge(options.fetch(:aria, {})))
  end
end
