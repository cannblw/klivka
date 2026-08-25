class TogglePillGroupComponent < ViewComponent::Base
  ACTIVE_CLASSES = "border-amber-600 bg-amber-50 text-amber-700 dark:border-amber-500 dark:bg-amber-900/30 dark:text-amber-400".freeze
  INACTIVE_CLASSES = "border-stone-200 bg-stone-50 text-stone-600 hover:border-stone-300 dark:border-stone-600 dark:bg-stone-800 dark:text-stone-300 dark:hover:border-stone-500".freeze

  def initialize(form:, field:, choices:, selected:, disabled: false, disabled_tooltip: nil, disabled_tooltip_id: nil, **radio_options)
    @form = form
    @field = field
    @choices = choices
    @selected = selected
    @disabled = disabled
    @disabled_tooltip = disabled_tooltip
    @disabled_tooltip_id = disabled_tooltip_id
    @radio_options = radio_options
  end

  private

  attr_reader :form, :field, :choices, :selected, :disabled_tooltip, :radio_options

  def pill_classes(value)
    base = "cursor-pointer select-none rounded-lg border px-4 py-2 text-sm font-medium transition"
    state = value.to_s == selected.to_s ? ACTIVE_CLASSES : INACTIVE_CLASSES
    "#{base} #{state}"
  end

  def disabled?
    @disabled
  end

  def tooltip?
    disabled? && disabled_tooltip
  end

  def tooltip_id
    @disabled_tooltip_id || "#{field}-disabled-tooltip"
  end

  def group_options
    return {} unless tooltip?

    { role: "group", tabindex: 0, aria: { disabled: true, describedby: tooltip_id } }
  end

  def input_options(value)
    radio_options.merge(
      checked: value.to_s == selected.to_s,
      disabled: disabled?,
      class: "sr-only"
    )
  end
end
