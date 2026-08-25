class BirthdayMonthNavigationComponent < ViewComponent::Base
  def initialize(selected_month:)
    @selected_month = selected_month
  end

  private

  attr_reader :selected_month

  def month_name(month)
    I18n.t("date.month_names").fetch(month)
  end

  def current_page?(month = nil)
    selected_month == month
  end

  def link_classes(active:)
    base = "shrink-0 rounded-lg px-3 py-2 text-sm font-medium transition"
    state = if active
      "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-200"
    else
      "text-stone-600 hover:bg-stone-100 hover:text-stone-900 dark:text-stone-300 dark:hover:bg-stone-700 dark:hover:text-stone-100"
    end

    "#{base} #{state}"
  end
end
