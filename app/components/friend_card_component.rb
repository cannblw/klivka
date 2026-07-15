class FriendCardComponent < ViewComponent::Base
  with_collection_parameter :friend

  def initialize(friend:)
    @friend = friend
  end

  private

  attr_reader :friend

  def initials
    friend.name.split.take(2).map { |part| part[0] }.join.upcase
  end
end
