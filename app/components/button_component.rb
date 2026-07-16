class ButtonComponent < ViewComponent::Base
  VARIANTS = {
    primary: "bg-indigo-600 text-white hover:bg-indigo-500",
    ghost: "text-gray-600 hover:bg-gray-100"
  }.freeze

  SIZES = {
    sm: "px-3 py-1.5",
    md: "px-4 py-2"
  }.freeze

  def initialize(variant: :primary, size: :md, type: :button, **options)
    @variant = variant.to_sym
    @size = size.to_sym
    @type = type
    @extra_classes = options.delete(:class)
    @options = options
  end

  private

  attr_reader :type, :options

  def classes
    [
      "cursor-pointer rounded-lg text-sm font-medium",
      SIZES.fetch(@size),
      VARIANTS.fetch(@variant),
      @extra_classes
    ].compact.join(" ")
  end
end
