class InlineNoticeComponent < ViewComponent::Base
  KINDS = {
    warning: {
      role: :note,
      classes: "bg-brand-surface text-brand-ink dark:bg-brand-dark-surface/40 dark:text-brand-on-dark"
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
