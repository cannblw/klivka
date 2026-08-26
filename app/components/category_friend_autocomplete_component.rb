class CategoryFriendAutocompleteComponent < ViewComponent::Base
  def initialize(category:)
    @category = category
  end

  private

  attr_reader :category

  def listbox_id
    "category-#{category.id}-friend-suggestions"
  end
end
