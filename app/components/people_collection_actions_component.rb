class PeopleCollectionActionsComponent < ViewComponent::Base
  def initialize(demo_mode:, **options)
    @demo_mode = demo_mode
    @extra_classes = options.delete(:class)
    @options = options
  end

  private

  attr_reader :options

  def classes
    [ "flex flex-wrap items-center gap-2", @extra_classes ].compact.join(" ")
  end

  def demo_mode?
    @demo_mode
  end

  def menu_item_classes
    "block w-full cursor-pointer rounded-lg px-4 py-2 text-left text-sm font-medium text-stone-600 hover:bg-stone-200 dark:text-stone-300 dark:hover:bg-stone-700"
  end
end
