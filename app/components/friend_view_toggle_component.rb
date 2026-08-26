class FriendViewToggleComponent < ViewComponent::Base
  def initialize(view:, sort:)
    @view = view
    @sort = sort
  end

  private

  attr_reader :view, :sort

  def path_for(selected_view)
    params = {}
    params[:view] = "all" if selected_view == "all"
    params[:sort] = sort unless sort == FriendSearch::DEFAULT_SORT
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
      data: { turbo_frame: "friends_grid", turbo_action: "advance" }
    }
  end
end
