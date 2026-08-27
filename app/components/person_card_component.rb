class PersonCardComponent < ViewComponent::Base
  with_collection_parameter :person

  def initialize(person:, show_category: false)
    @person = person
    @show_category = show_category
  end

  private

  attr_reader :person

  def show_category?
    @show_category && person.category.present?
  end
end
