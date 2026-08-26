class FriendCardComponent < ViewComponent::Base
  with_collection_parameter :friend

  def initialize(friend:, show_category: false)
    @friend = friend
    @show_category = show_category
  end

  private

  attr_reader :friend

  def show_category?
    @show_category && friend.category.present?
  end
end
