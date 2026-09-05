class ButtonComponent < ViewComponent::Base
  VARIANTS = {
    primary: "bg-brand-action text-white hover:bg-brand-action-hover",
    destructive: "bg-red-600 text-white hover:bg-red-500",
    ghost: "text-stone-600 hover:bg-stone-200 dark:text-stone-300 dark:hover:bg-stone-700"
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
      "cursor-pointer rounded-lg text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50",
      SIZES.fetch(@size),
      VARIANTS.fetch(@variant),
      @extra_classes
    ].compact.join(" ")
  end
end
