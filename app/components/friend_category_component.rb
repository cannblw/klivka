class FriendCategoryComponent < ViewComponent::Base
  def initialize(friend:, categories:)
    @friend = friend
    @categories = categories
  end

  private

  attr_reader :friend, :categories
end
