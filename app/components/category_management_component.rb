class CategoryManagementComponent < ViewComponent::Base
  with_collection_parameter :category

  def initialize(category:)
    @category = category
  end

  private

  attr_reader :category

  def person_count
    category.association(:active_people).loaded? ? category.active_people.size : category.active_people.count
  end
end
