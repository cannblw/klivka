class CategoryManagementComponent < ViewComponent::Base
  with_collection_parameter :category

  def initialize(category:)
    @category = category
  end

  private

  attr_reader :category

  def friend_count
    category.association(:friends).loaded? ? category.friends.size : category.friends.count
  end
end
