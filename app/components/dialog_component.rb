class DialogComponent < ViewComponent::Base
  SIZES = {
    sm: "w-full max-w-sm",
    lg: "w-[calc(100%_-_2rem)] max-w-lg"
  }.freeze

  def initialize(id: nil, labelledby: nil, describedby: nil, size: :sm, **options)
    raise ArgumentError, "unknown dialog size: #{size}" unless SIZES.key?(size)
    unless labelledby.present? || options.dig(:aria, :label).present?
      raise ArgumentError, "dialog requires labelledby or aria-label"
    end

    @id = id
    @labelledby = labelledby
    @describedby = describedby
    @size = size
    @options = options
  end

  private

  attr_reader :id, :labelledby, :describedby, :size, :options

  def dialog_options
    attributes = options.deep_dup
    attributes[:id] = id if id
    attributes[:aria] = attributes.fetch(:aria, {}).merge(
      { labelledby:, describedby: }.compact
    )
    attributes[:class] = [
      "m-auto rounded-xl p-0 shadow-xl backdrop:bg-stone-900/50 dark:bg-stone-800",
      SIZES.fetch(size),
      options[:class]
    ].compact.join(" ")
    attributes
  end
end
