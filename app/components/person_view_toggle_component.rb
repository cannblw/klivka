class PersonViewToggleComponent < ViewComponent::Base
  def initialize(view:, query_params: {})
    @view = view
    @query_params = query_params
  end

  private

  attr_reader :view, :query_params

  def path_for(selected_view)
    params = query_params.dup
    params[:view] = "all" if selected_view == "all"
    helpers.root_path(**params)
  end

  def link_classes(selected_view)
    base = "rounded-lg px-3 py-1.5 text-sm font-medium transition"
    selected = "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
    unselected = "text-stone-600 hover:bg-stone-100 dark:text-stone-300 dark:hover:bg-stone-700"
    "#{base} #{view == selected_view ? selected : unselected}"
  end

  def link_options(selected_view)
    {
      class: link_classes(selected_view),
      aria: { current: view == selected_view ? "true" : nil },
      data: { turbo_frame: "people_grid", turbo_action: "advance" }
    }
  end
end
