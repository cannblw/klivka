class FriendCardComponent < ViewComponent::Base
  with_collection_parameter :friend

  def initialize(friend:)
    @friend = friend
  end

  private

  attr_reader :friend
end
