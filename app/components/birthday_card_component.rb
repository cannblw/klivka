class BirthdayCardComponent < ViewComponent::Base
  with_collection_parameter :birthday

  def initialize(birthday:)
    @birthday = birthday
  end

  private

  attr_reader :birthday

  def friend
    birthday.friend
  end
end
