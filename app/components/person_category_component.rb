class PersonCategoryComponent < ViewComponent::Base
  def initialize(person:, categories:)
    @person = person
    @categories = categories
  end

  private

  attr_reader :person, :categories
end
