class CategoryPersonAutocompleteComponent < ViewComponent::Base
  def initialize(category:)
    @category = category
  end

  private

  attr_reader :category

  def listbox_id
    "category-#{category.id}-person-suggestions"
  end
end
