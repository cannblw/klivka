class InlineNoticeComponent < ViewComponent::Base
  KINDS = {
    warning: {
      role: :note,
      classes: "bg-amber-50 text-amber-900 dark:bg-amber-950/40 dark:text-amber-200"
    }
  }.freeze

  def initialize(kind: :warning, **options)
    @kind = KINDS.fetch(kind.to_sym)
    @extra_classes = options.delete(:class)
    @options = options
  end

  def call
    tag.div(content, role: kind.fetch(:role), class: classes, **options)
  end

  private

  attr_reader :kind, :extra_classes, :options

  def classes
    [ "rounded-lg px-4 py-3 text-sm", kind.fetch(:classes), extra_classes ].compact.join(" ")
  end
end
