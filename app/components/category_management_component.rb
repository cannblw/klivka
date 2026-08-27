class CategoryManagementComponent < ViewComponent::Base
  with_collection_parameter :category

  def initialize(category:)
    @category = category
  end

  private

  attr_reader :category

  def person_count
    category.association(:people).loaded? ? category.people.size : category.people.count
  end
end
