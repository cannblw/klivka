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
    "rounded-lg px-3 py-1.5 text-sm font-medium text-stone-600 transition hover:bg-stone-100 aria-[current=true]:bg-amber-50 aria-[current=true]:text-amber-700 dark:text-stone-300 dark:hover:bg-stone-700 dark:aria-[current=true]:bg-amber-900/30 dark:aria-[current=true]:text-amber-400"
  end

  def link_options(selected_view)
    {
      class: link_classes(selected_view),
      aria: { current: view == selected_view ? "true" : "false" },
      data: { turbo_frame: "people_grid", turbo_action: "advance", search_target: "view", person_view_value: selected_view }
    }
  end
end
